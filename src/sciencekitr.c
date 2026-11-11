#include "sciencekitr.h"
#include "sciencekit.h"

#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

typedef enum SKRHandleKind {
    SK_R_HANDLE_BUILDER = 1,
    SK_R_HANDLE_MODEL = 2
} SKRHandleKind;

typedef struct SKRHandleBox {
    SKRHandleKind kind;
    void *raw;
} SKRHandleBox;

static size_t live_builders = 0;
static size_t live_models = 0;

static SEXP ok_result(SEXP value) {
    PROTECT(value);
    SEXP names = PROTECT(Rf_allocVector(STRSXP, 2));
    SET_STRING_ELT(names, 0, Rf_mkChar("ok"));
    SET_STRING_ELT(names, 1, Rf_mkChar("value"));

    SEXP out = PROTECT(Rf_allocVector(VECSXP, 2));
    SET_VECTOR_ELT(out, 0, Rf_ScalarLogical(1));
    SET_VECTOR_ELT(out, 1, value);
    Rf_setAttrib(out, R_NamesSymbol, names);

    UNPROTECT(3);
    return out;
}

static SEXP err_result(SKFfiStatus status, const char *message) {
    const char *status_str = sk_ffi_status_name((int32_t)status);
    if (status_str == NULL) {
        status_str = "unknown";
    }
    const char *msg_str = (message != NULL && message[0] != '\0') ? message : status_str;

    SEXP names = PROTECT(Rf_allocVector(STRSXP, 4));
    SET_STRING_ELT(names, 0, Rf_mkChar("ok"));
    SET_STRING_ELT(names, 1, Rf_mkChar("status_code"));
    SET_STRING_ELT(names, 2, Rf_mkChar("status"));
    SET_STRING_ELT(names, 3, Rf_mkChar("message"));

    SEXP out = PROTECT(Rf_allocVector(VECSXP, 4));
    SET_VECTOR_ELT(out, 0, Rf_ScalarLogical(0));
    SET_VECTOR_ELT(out, 1, Rf_ScalarInteger((int)status));
    SET_VECTOR_ELT(out, 2, Rf_mkString(status_str));
    SET_VECTOR_ELT(out, 3, Rf_mkString(msg_str));
    Rf_setAttrib(out, R_NamesSymbol, names);

    UNPROTECT(2);
    return out;
}

static SKFfiStatus classify_null_pointer_error(const char *message) {
    if (message == NULL || message[0] == '\0') {
        return SK_FFI_STATUS_INTERNAL;
    }
    if (strncmp(message, "invalid handle", 14) == 0) {
        return SK_FFI_STATUS_INVALID_HANDLE;
    }
    if (strstr(message, "shape") != NULL || strstr(message, "dimension") != NULL ||
        strstr(message, "rows") != NULL || strstr(message, "columns") != NULL) {
        return SK_FFI_STATUS_SHAPE;
    }
    if (strncmp(message, "operation `", 11) == 0 &&
        strstr(message, "is not supported") != NULL) {
        return SK_FFI_STATUS_UNSUPPORTED;
    }
    if (strstr(message, "not been fitted") != NULL) {
        return SK_FFI_STATUS_NOT_FITTED;
    }
    if (strncmp(message, "I/O error:", 10) == 0) {
        return SK_FFI_STATUS_IO;
    }
    if (strncmp(message, "internal error:", 15) == 0 ||
        strncmp(message, "panic:", 6) == 0) {
        return SK_FFI_STATUS_INTERNAL;
    }
    return SK_FFI_STATUS_INVALID_ARGUMENT;
}

static SKFfiStatus release_handle_box(SKRHandleBox *box, bool *did_release) {
    if (did_release != NULL) {
        *did_release = false;
    }
    if (box == NULL || box->raw == NULL) {
        return SK_FFI_STATUS_OK;
    }
    void *raw = box->raw;
    box->raw = NULL;

    SKFfiStatus status = SK_FFI_STATUS_OK;
    if (box->kind == SK_R_HANDLE_BUILDER) {
        status = sk_ffi_builder_free((SKFfiBuilder *)raw);
        if (live_builders > 0) {
            live_builders -= 1;
        }
    } else if (box->kind == SK_R_HANDLE_MODEL) {
        status = sk_ffi_model_free((SKFfiModel *)raw);
        if (live_models > 0) {
            live_models -= 1;
        }
    }
    if (did_release != NULL) {
        *did_release = true;
    }
    return status;
}

static void c_sciencekit_finalize_handle(SEXP extptr) {
    if (TYPEOF(extptr) != EXTPTRSXP) {
        return;
    }
    SKRHandleBox *box = (SKRHandleBox *)R_ExternalPtrAddr(extptr);
    if (box != NULL) {
        (void)release_handle_box(box, NULL);
        free(box);
        R_ClearExternalPtr(extptr);
    }
}

static SEXP wrap_handle(SKRHandleKind kind, void *raw, const char *tag_name) {
    SKRHandleBox *box = (SKRHandleBox *)calloc(1, sizeof(SKRHandleBox));
    if (box == NULL) {
        if (kind == SK_R_HANDLE_BUILDER) {
            (void)sk_ffi_builder_free((SKFfiBuilder *)raw);
        } else {
            (void)sk_ffi_model_free((SKFfiModel *)raw);
        }
        return err_result(SK_FFI_STATUS_INTERNAL,
                          "internal error: cannot allocate handle wrapper");
    }
    box->kind = kind;
    box->raw = raw;
    if (kind == SK_R_HANDLE_BUILDER) {
        live_builders += 1;
    } else {
        live_models += 1;
    }

    SEXP ptr = PROTECT(R_MakeExternalPtr(box, Rf_install(tag_name), R_NilValue));
    R_RegisterCFinalizerEx(ptr, c_sciencekit_finalize_handle, TRUE);
    SEXP res = PROTECT(ok_result(ptr));
    UNPROTECT(2);
    return res;
}

static SKFfiBuilder *resolve_builder(SEXP ptr_sexp) {
    if (TYPEOF(ptr_sexp) != EXTPTRSXP) {
        return NULL;
    }
    SKRHandleBox *box = (SKRHandleBox *)R_ExternalPtrAddr(ptr_sexp);
    if (box == NULL || box->kind != SK_R_HANDLE_BUILDER || box->raw == NULL) {
        return NULL;
    }
    return (SKFfiBuilder *)box->raw;
}

static SKFfiModel *resolve_model(SEXP ptr_sexp) {
    if (TYPEOF(ptr_sexp) != EXTPTRSXP) {
        return NULL;
    }
    SKRHandleBox *box = (SKRHandleBox *)R_ExternalPtrAddr(ptr_sexp);
    if (box == NULL || box->kind != SK_R_HANDLE_MODEL || box->raw == NULL) {
        return NULL;
    }
    return (SKFfiModel *)box->raw;
}

static bool copy_r_matrix_to_row_major(SEXP mat_sexp,
                                       double **out_buffer,
                                       int64_t out_shape[2],
                                       int64_t *out_len) {
    SEXP dim = Rf_getAttrib(mat_sexp, R_DimSymbol);
    if (TYPEOF(mat_sexp) != REALSXP || TYPEOF(dim) != INTSXP ||
        Rf_length(dim) != 2) {
        return false;
    }
    int nrow = INTEGER(dim)[0];
    int ncol = INTEGER(dim)[1];
    if (nrow <= 0 || ncol <= 0) {
        return false;
    }
    size_t rows = (size_t)nrow;
    size_t cols = (size_t)ncol;
    size_t total = rows * cols;
    double *buffer = (double *)malloc(total * sizeof(double));
    if (buffer == NULL) {
        return false;
    }

    const double *src = REAL(mat_sexp);
    for (size_t r = 0; r < rows; ++r) {
        for (size_t c = 0; c < cols; ++c) {
            buffer[r * cols + c] = src[r + c * rows];
        }
    }

    *out_buffer = buffer;
    out_shape[0] = (int64_t)nrow;
    out_shape[1] = (int64_t)ncol;
    *out_len = (int64_t)total;
    return true;
}

static bool copy_r_vector_f64(SEXP vec_sexp,
                              double **out_buffer,
                              int64_t out_shape[1],
                              int64_t *out_len) {
    if (TYPEOF(vec_sexp) != REALSXP) {
        return false;
    }
    R_xlen_t len = XLENGTH(vec_sexp);
    if (len <= 0) {
        return false;
    }
    size_t total = (size_t)len;
    double *buffer = (double *)malloc(total * sizeof(double));
    if (buffer == NULL) {
        return false;
    }
    memcpy(buffer, REAL(vec_sexp), total * sizeof(double));
    *out_buffer = buffer;
    out_shape[0] = (int64_t)len;
    *out_len = (int64_t)len;
    return true;
}

SEXP c_sciencekit_version(void) {
    int32_t major = 0;
    int32_t minor = 0;
    int32_t patch = 0;
    SKFfiStatus status = sk_ffi_version(&major, &minor, &patch);
    if (status != SK_FFI_STATUS_OK) {
        return err_result(status, sk_ffi_last_error());
    }

    SEXP vec = PROTECT(Rf_allocVector(INTSXP, 3));
    INTEGER(vec)[0] = (int)major;
    INTEGER(vec)[1] = (int)minor;
    INTEGER(vec)[2] = (int)patch;

    SEXP names = PROTECT(Rf_allocVector(STRSXP, 3));
    SET_STRING_ELT(names, 0, Rf_mkChar("major"));
    SET_STRING_ELT(names, 1, Rf_mkChar("minor"));
    SET_STRING_ELT(names, 2, Rf_mkChar("patch"));
    Rf_setAttrib(vec, R_NamesSymbol, names);

    SEXP res = PROTECT(ok_result(vec));
    UNPROTECT(3);
    return res;
}

SEXP c_sciencekit_features(void) {
    uint64_t bits = sk_ffi_features();
    SEXP vec = PROTECT(Rf_allocVector(LGLSXP, 5));
    LOGICAL(vec)[0] = (bits & SK_FFI_FEATURE_LINEAR_REGRESSION) != 0 ? 1 : 0;
    LOGICAL(vec)[1] = (bits & SK_FFI_FEATURE_STANDARD_SCALER) != 0 ? 1 : 0;
    LOGICAL(vec)[2] = (bits & SK_FFI_FEATURE_MODEL_PERSISTENCE) != 0 ? 1 : 0;
    LOGICAL(vec)[3] = (bits & SK_FFI_FEATURE_F32) != 0 ? 1 : 0;
    LOGICAL(vec)[4] = (bits & SK_FFI_FEATURE_F64) != 0 ? 1 : 0;

    SEXP names = PROTECT(Rf_allocVector(STRSXP, 5));
    SET_STRING_ELT(names, 0, Rf_mkChar("linear_regression"));
    SET_STRING_ELT(names, 1, Rf_mkChar("standard_scaler"));
    SET_STRING_ELT(names, 2, Rf_mkChar("model_persistence"));
    SET_STRING_ELT(names, 3, Rf_mkChar("f32"));
    SET_STRING_ELT(names, 4, Rf_mkChar("f64"));
    Rf_setAttrib(vec, R_NamesSymbol, names);

    SEXP res = PROTECT(ok_result(vec));
    UNPROTECT(3);
    return res;
}

SEXP c_sciencekit_status_name(SEXP status_sexp) {
    int code = Rf_asInteger(status_sexp);
    const char *name = sk_ffi_status_name((int32_t)code);
    if (name == NULL) {
        name = "unknown";
    }
    return Rf_mkString(name);
}

SEXP c_sciencekit_live_counts(void) {
    SEXP vec = PROTECT(Rf_allocVector(INTSXP, 2));
    INTEGER(vec)[0] = (int)live_builders;
    INTEGER(vec)[1] = (int)live_models;

    SEXP names = PROTECT(Rf_allocVector(STRSXP, 2));
    SET_STRING_ELT(names, 0, Rf_mkChar("builders"));
    SET_STRING_ELT(names, 1, Rf_mkChar("models"));
    Rf_setAttrib(vec, R_NamesSymbol, names);

    UNPROTECT(2);
    return vec;
}

SEXP c_sciencekit_builder_create(SEXP family_sexp, SEXP dtype_sexp) {
    int32_t family = (int32_t)Rf_asInteger(family_sexp);
    int32_t dtype = (int32_t)Rf_asInteger(dtype_sexp);

    SKFfiBuilder *builder = sk_ffi_builder_create(family, dtype);
    if (builder == NULL) {
        const char *msg = sk_ffi_last_error();
        return err_result(classify_null_pointer_error(msg), msg);
    }
    return wrap_handle(SK_R_HANDLE_BUILDER, builder, "sciencekit_builder_ptr");
}

SEXP c_sciencekit_builder_set_include_intercept(SEXP ptr_sexp, SEXP enabled_sexp) {
    SKFfiBuilder *builder = resolve_builder(ptr_sexp);
    if (builder == NULL) {
        return err_result(SK_FFI_STATUS_INVALID_HANDLE,
                          "invalid handle: the builder handle is closed or invalid");
    }
    bool enabled = Rf_asLogical(enabled_sexp) == 1;
    SKFfiStatus status = sk_ffi_builder_set_include_intercept(builder, enabled);
    if (status != SK_FFI_STATUS_OK) {
        return err_result(status, sk_ffi_last_error());
    }
    return ok_result(Rf_ScalarLogical(1));
}

SEXP c_sciencekit_builder_set_with_mean(SEXP ptr_sexp, SEXP enabled_sexp) {
    SKFfiBuilder *builder = resolve_builder(ptr_sexp);
    if (builder == NULL) {
        return err_result(SK_FFI_STATUS_INVALID_HANDLE,
                          "invalid handle: the builder handle is closed or invalid");
    }
    bool enabled = Rf_asLogical(enabled_sexp) == 1;
    SKFfiStatus status = sk_ffi_builder_set_with_mean(builder, enabled);
    if (status != SK_FFI_STATUS_OK) {
        return err_result(status, sk_ffi_last_error());
    }
    return ok_result(Rf_ScalarLogical(1));
}

SEXP c_sciencekit_builder_set_with_std(SEXP ptr_sexp, SEXP enabled_sexp) {
    SKFfiBuilder *builder = resolve_builder(ptr_sexp);
    if (builder == NULL) {
        return err_result(SK_FFI_STATUS_INVALID_HANDLE,
                          "invalid handle: the builder handle is closed or invalid");
    }
    bool enabled = Rf_asLogical(enabled_sexp) == 1;
    SKFfiStatus status = sk_ffi_builder_set_with_std(builder, enabled);
    if (status != SK_FFI_STATUS_OK) {
        return err_result(status, sk_ffi_last_error());
    }
    return ok_result(Rf_ScalarLogical(1));
}

SEXP c_sciencekit_builder_set_backend(SEXP ptr_sexp, SEXP backend_sexp) {
    SKFfiBuilder *builder = resolve_builder(ptr_sexp);
    if (builder == NULL) {
        return err_result(SK_FFI_STATUS_INVALID_HANDLE,
                          "invalid handle: the builder handle is closed or invalid");
    }
    int32_t backend = (int32_t)Rf_asInteger(backend_sexp);
    SKFfiStatus status = sk_ffi_builder_set_backend(builder, backend);
    if (status != SK_FFI_STATUS_OK) {
        return err_result(status, sk_ffi_last_error());
    }
    return ok_result(Rf_ScalarLogical(1));
}

SEXP c_sciencekit_handle_close(SEXP ptr_sexp) {
    if (TYPEOF(ptr_sexp) != EXTPTRSXP) {
        return err_result(SK_FFI_STATUS_INVALID_HANDLE,
                          "invalid handle: expected an external pointer");
    }
    SKRHandleBox *box = (SKRHandleBox *)R_ExternalPtrAddr(ptr_sexp);
    bool released = false;
    SKFfiStatus status = release_handle_box(box, &released);
    if (status != SK_FFI_STATUS_OK) {
        return err_result(status, sk_ffi_last_error());
    }
    return ok_result(Rf_ScalarLogical(released ? 1 : 0));
}

SEXP c_sciencekit_handle_is_closed(SEXP ptr_sexp) {
    if (TYPEOF(ptr_sexp) != EXTPTRSXP) {
        return Rf_ScalarLogical(1);
    }
    SKRHandleBox *box = (SKRHandleBox *)R_ExternalPtrAddr(ptr_sexp);
    return Rf_ScalarLogical((box == NULL || box->raw == NULL) ? 1 : 0);
}

SEXP c_sciencekit_fit(SEXP builder_sexp, SEXP features_sexp, SEXP targets_sexp) {
    SKFfiBuilder *builder = resolve_builder(builder_sexp);
    if (builder == NULL) {
        return err_result(SK_FFI_STATUS_INVALID_HANDLE,
                          "invalid handle: the builder handle is closed or invalid");
    }

    double *feat_buf = NULL;
    int64_t feat_shape[2] = {0, 0};
    int64_t feat_len = 0;
    if (!copy_r_matrix_to_row_major(features_sexp, &feat_buf, feat_shape, &feat_len)) {
        return err_result(SK_FFI_STATUS_INVALID_ARGUMENT,
                          "features must be a non-empty double matrix");
    }

    SKFfiArray feat_desc;
    memset(&feat_desc, 0, sizeof(feat_desc));
    feat_desc.dtype = SK_FFI_DTYPE_F64;
    feat_desc.ndim = 2;
    feat_desc.shape = feat_shape;
    feat_desc.strides = NULL;
    feat_desc.data = feat_buf;
    feat_desc.len = feat_len;

    double *target_buf = NULL;
    int64_t target_shape[1] = {0};
    int64_t target_len = 0;
    SKFfiArray target_desc;
    memset(&target_desc, 0, sizeof(target_desc));
    const SKFfiArray *target_ptr = NULL;

    if (targets_sexp != R_NilValue) {
        if (!copy_r_vector_f64(targets_sexp, &target_buf, target_shape, &target_len)) {
            free(feat_buf);
            return err_result(SK_FFI_STATUS_INVALID_ARGUMENT,
                              "targets must be a non-empty double vector");
        }
        target_desc.dtype = SK_FFI_DTYPE_F64;
        target_desc.ndim = 1;
        target_desc.shape = target_shape;
        target_desc.strides = NULL;
        target_desc.data = target_buf;
        target_desc.len = target_len;
        target_ptr = &target_desc;
    }

    SKFfiModel *model = sk_ffi_fit(builder, &feat_desc, target_ptr);
    free(feat_buf);
    free(target_buf);

    if (model == NULL) {
        const char *msg = sk_ffi_last_error();
        return err_result(classify_null_pointer_error(msg), msg);
    }

    return wrap_handle(SK_R_HANDLE_MODEL, model, "sciencekit_model_ptr");
}

SEXP c_sciencekit_predict(SEXP model_sexp, SEXP features_sexp) {
    SKFfiModel *model = resolve_model(model_sexp);
    if (model == NULL) {
        return err_result(SK_FFI_STATUS_INVALID_HANDLE,
                          "invalid handle: the model handle is closed or invalid");
    }

    double *feat_buf = NULL;
    int64_t feat_shape[2] = {0, 0};
    int64_t feat_len = 0;
    if (!copy_r_matrix_to_row_major(features_sexp, &feat_buf, feat_shape, &feat_len)) {
        return err_result(SK_FFI_STATUS_INVALID_ARGUMENT,
                          "features must be a non-empty double matrix");
    }

    SKFfiArray feat_desc;
    memset(&feat_desc, 0, sizeof(feat_desc));
    feat_desc.dtype = SK_FFI_DTYPE_F64;
    feat_desc.ndim = 2;
    feat_desc.shape = feat_shape;
    feat_desc.strides = NULL;
    feat_desc.data = feat_buf;
    feat_desc.len = feat_len;

    SKFfiArray output;
    memset(&output, 0, sizeof(output));

    SKFfiStatus status = sk_ffi_predict(model, &feat_desc, &output);
    free(feat_buf);

    if (status != SK_FFI_STATUS_OK) {
        return err_result(status, sk_ffi_last_error());
    }

    R_xlen_t n = (R_xlen_t)output.len;
    SEXP r_vec = PROTECT(Rf_allocVector(REALSXP, n));
    if (n > 0 && output.data != NULL) {
        memcpy(REAL(r_vec), output.data, (size_t)n * sizeof(double));
    }
    (void)sk_ffi_array_free(&output);

    SEXP res = PROTECT(ok_result(r_vec));
    UNPROTECT(2);
    return res;
}

SEXP c_sciencekit_transform(SEXP model_sexp, SEXP features_sexp) {
    SKFfiModel *model = resolve_model(model_sexp);
    if (model == NULL) {
        return err_result(SK_FFI_STATUS_INVALID_HANDLE,
                          "invalid handle: the model handle is closed or invalid");
    }

    double *feat_buf = NULL;
    int64_t feat_shape[2] = {0, 0};
    int64_t feat_len = 0;
    if (!copy_r_matrix_to_row_major(features_sexp, &feat_buf, feat_shape, &feat_len)) {
        return err_result(SK_FFI_STATUS_INVALID_ARGUMENT,
                          "features must be a non-empty double matrix");
    }

    SKFfiArray feat_desc;
    memset(&feat_desc, 0, sizeof(feat_desc));
    feat_desc.dtype = SK_FFI_DTYPE_F64;
    feat_desc.ndim = 2;
    feat_desc.shape = feat_shape;
    feat_desc.strides = NULL;
    feat_desc.data = feat_buf;
    feat_desc.len = feat_len;

    SKFfiArray output;
    memset(&output, 0, sizeof(output));

    SKFfiStatus status = sk_ffi_transform(model, &feat_desc, &output);
    free(feat_buf);

    if (status != SK_FFI_STATUS_OK) {
        return err_result(status, sk_ffi_last_error());
    }

    if (output.ndim != 2 || output.shape == NULL || output.data == NULL) {
        (void)sk_ffi_array_free(&output);
        return err_result(SK_FFI_STATUS_INTERNAL,
                          "internal error: transform did not return a 2D array");
    }

    int out_rows = (int)output.shape[0];
    int out_cols = (int)output.shape[1];
    size_t rows = (size_t)out_rows;
    size_t cols = (size_t)out_cols;

    SEXP r_mat = PROTECT(Rf_allocMatrix(REALSXP, out_rows, out_cols));
    double *dst = REAL(r_mat);
    const double *src = (const double *)output.data;
    for (size_t r = 0; r < rows; ++r) {
        for (size_t c = 0; c < cols; ++c) {
            dst[r + c * rows] = src[r * cols + c];
        }
    }
    (void)sk_ffi_array_free(&output);

    SEXP res = PROTECT(ok_result(r_mat));
    UNPROTECT(2);
    return res;
}

SEXP c_sciencekit_score(SEXP model_sexp, SEXP features_sexp, SEXP targets_sexp) {
    SKFfiModel *model = resolve_model(model_sexp);
    if (model == NULL) {
        return err_result(SK_FFI_STATUS_INVALID_HANDLE,
                          "invalid handle: the model handle is closed or invalid");
    }

    double *feat_buf = NULL;
    int64_t feat_shape[2] = {0, 0};
    int64_t feat_len = 0;
    if (!copy_r_matrix_to_row_major(features_sexp, &feat_buf, feat_shape, &feat_len)) {
        return err_result(SK_FFI_STATUS_INVALID_ARGUMENT,
                          "features must be a non-empty double matrix");
    }

    double *target_buf = NULL;
    int64_t target_shape[1] = {0};
    int64_t target_len = 0;
    if (!copy_r_vector_f64(targets_sexp, &target_buf, target_shape, &target_len)) {
        free(feat_buf);
        return err_result(SK_FFI_STATUS_INVALID_ARGUMENT,
                          "targets must be a non-empty double vector");
    }

    SKFfiArray feat_desc;
    memset(&feat_desc, 0, sizeof(feat_desc));
    feat_desc.dtype = SK_FFI_DTYPE_F64;
    feat_desc.ndim = 2;
    feat_desc.shape = feat_shape;
    feat_desc.strides = NULL;
    feat_desc.data = feat_buf;
    feat_desc.len = feat_len;

    SKFfiArray target_desc;
    memset(&target_desc, 0, sizeof(target_desc));
    target_desc.dtype = SK_FFI_DTYPE_F64;
    target_desc.ndim = 1;
    target_desc.shape = target_shape;
    target_desc.strides = NULL;
    target_desc.data = target_buf;
    target_desc.len = target_len;

    double score_value = 0.0;
    SKFfiStatus status = sk_ffi_score(model, &feat_desc, &target_desc, &score_value);
    free(feat_buf);
    free(target_buf);

    if (status != SK_FFI_STATUS_OK) {
        return err_result(status, sk_ffi_last_error());
    }
    return ok_result(Rf_ScalarReal(score_value));
}

SEXP c_sciencekit_model_save(SEXP model_sexp, SEXP path_sexp) {
    SKFfiModel *model = resolve_model(model_sexp);
    if (model == NULL) {
        return err_result(SK_FFI_STATUS_INVALID_HANDLE,
                          "invalid handle: the model handle is closed or invalid");
    }
    if (TYPEOF(path_sexp) != STRSXP || Rf_length(path_sexp) != 1 ||
        STRING_ELT(path_sexp, 0) == NA_STRING) {
        return err_result(SK_FFI_STATUS_INVALID_ARGUMENT,
                          "path must be a non-missing character scalar");
    }
    const char *path = Rf_translateCharUTF8(STRING_ELT(path_sexp, 0));
    SKFfiStatus status = sk_ffi_model_save(model, path);
    if (status != SK_FFI_STATUS_OK) {
        return err_result(status, sk_ffi_last_error());
    }
    return ok_result(Rf_ScalarLogical(1));
}

SEXP c_sciencekit_model_load(SEXP path_sexp) {
    if (TYPEOF(path_sexp) != STRSXP || Rf_length(path_sexp) != 1 ||
        STRING_ELT(path_sexp, 0) == NA_STRING) {
        return err_result(SK_FFI_STATUS_INVALID_ARGUMENT,
                          "path must be a non-missing character scalar");
    }
    const char *path = Rf_translateCharUTF8(STRING_ELT(path_sexp, 0));
    SKFfiModel *model = NULL;
    SKFfiStatus status = sk_ffi_model_load(path, &model);
    if (status != SK_FFI_STATUS_OK || model == NULL) {
        return err_result(status != SK_FFI_STATUS_OK ? status : SK_FFI_STATUS_IO,
                          sk_ffi_last_error());
    }
    return wrap_handle(SK_R_HANDLE_MODEL, model, "sciencekit_model_ptr");
}

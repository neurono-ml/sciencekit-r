#include "sciencekitr.h"

#include <R_ext/Rdynload.h>
#include <stddef.h>

static const R_CallMethodDef call_methods[] = {
    {"C_sciencekit_version", (DL_FUNC)&c_sciencekit_version, 0},
    {"C_sciencekit_features", (DL_FUNC)&c_sciencekit_features, 0},
    {"C_sciencekit_status_name", (DL_FUNC)&c_sciencekit_status_name, 1},
    {"C_sciencekit_live_counts", (DL_FUNC)&c_sciencekit_live_counts, 0},
    {"C_sciencekit_builder_create", (DL_FUNC)&c_sciencekit_builder_create, 2},
    {"C_sciencekit_builder_set_include_intercept",
     (DL_FUNC)&c_sciencekit_builder_set_include_intercept, 2},
    {"C_sciencekit_builder_set_with_mean",
     (DL_FUNC)&c_sciencekit_builder_set_with_mean, 2},
    {"C_sciencekit_builder_set_with_std",
     (DL_FUNC)&c_sciencekit_builder_set_with_std, 2},
    {"C_sciencekit_builder_set_backend",
     (DL_FUNC)&c_sciencekit_builder_set_backend, 2},
    {"C_sciencekit_handle_close", (DL_FUNC)&c_sciencekit_handle_close, 1},
    {"C_sciencekit_handle_is_closed", (DL_FUNC)&c_sciencekit_handle_is_closed,
     1},
    {"C_sciencekit_fit", (DL_FUNC)&c_sciencekit_fit, 3},
    {"C_sciencekit_predict", (DL_FUNC)&c_sciencekit_predict, 2},
    {"C_sciencekit_transform", (DL_FUNC)&c_sciencekit_transform, 2},
    {"C_sciencekit_score", (DL_FUNC)&c_sciencekit_score, 3},
    {"C_sciencekit_model_save", (DL_FUNC)&c_sciencekit_model_save, 2},
    {"C_sciencekit_model_load", (DL_FUNC)&c_sciencekit_model_load, 1},
    {NULL, NULL, 0}};

void R_init_sciencekitr(DllInfo *dll) {
    R_registerRoutines(dll, NULL, call_methods, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
    R_forceSymbols(dll, TRUE);
}

#ifndef SCIENCEKITR_H
#define SCIENCEKITR_H

#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>

SEXP c_sciencekit_version(void);
SEXP c_sciencekit_features(void);
SEXP c_sciencekit_status_name(SEXP status_sexp);
SEXP c_sciencekit_live_counts(void);

SEXP c_sciencekit_builder_create(SEXP family_sexp, SEXP dtype_sexp);
SEXP c_sciencekit_builder_set_include_intercept(SEXP ptr_sexp, SEXP enabled_sexp);
SEXP c_sciencekit_builder_set_with_mean(SEXP ptr_sexp, SEXP enabled_sexp);
SEXP c_sciencekit_builder_set_with_std(SEXP ptr_sexp, SEXP enabled_sexp);
SEXP c_sciencekit_builder_set_backend(SEXP ptr_sexp, SEXP backend_sexp);

SEXP c_sciencekit_handle_close(SEXP ptr_sexp);
SEXP c_sciencekit_handle_is_closed(SEXP ptr_sexp);

SEXP c_sciencekit_fit(SEXP builder_sexp, SEXP features_sexp, SEXP targets_sexp);
SEXP c_sciencekit_predict(SEXP model_sexp, SEXP features_sexp);
SEXP c_sciencekit_transform(SEXP model_sexp, SEXP features_sexp);
SEXP c_sciencekit_score(SEXP model_sexp, SEXP features_sexp, SEXP targets_sexp);
SEXP c_sciencekit_model_save(SEXP model_sexp, SEXP path_sexp);
SEXP c_sciencekit_model_load(SEXP path_sexp);

#endif /* SCIENCEKITR_H */

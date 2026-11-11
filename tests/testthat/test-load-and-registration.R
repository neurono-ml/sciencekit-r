test_that("package loads and exports documented surface", {
  exports <- getNamespaceExports("sciencekitr")
  expect_true(all(c(
    "abi_version",
    "abi_features",
    "sk_builder",
    "sk_linear_regression",
    "sk_standard_scaler",
    "set_include_intercept",
    "set_with_mean",
    "set_with_std",
    "set_backend",
    "fit",
    "sk_transform",
    "score",
    "save_model",
    "load_model",
    "is_closed",
    "live_handle_counts"
  ) %in% exports))

  ver <- abi_version()
  expect_identical(ver, c(major = 1L, minor = 0L, patch = 0L))

  feats <- abi_features()
  expect_true(feats[["linear_regression"]])
  expect_true(feats[["standard_scaler"]])
  expect_true(feats[["model_persistence"]])
  expect_true(feats[["f64"]])
})

test_that("native routines are registered and dynamic symbol lookup is disabled", {
  routines <- getDLLRegisteredRoutines("sciencekitr")[[".Call"]]
  expect_true("C_sciencekit_version" %in% names(routines))
  expect_true("C_sciencekit_fit" %in% names(routines))
  expect_true("C_sciencekit_predict" %in% names(routines))
  expect_true("C_sciencekit_transform" %in% names(routines))
  expect_true("C_sciencekit_score" %in% names(routines))
  expect_true("C_sciencekit_model_save" %in% names(routines))
  expect_true("C_sciencekit_model_load" %in% names(routines))
  expect_true("C_sciencekit_handle_close" %in% names(routines))

  # Unregistered C symbols and string-based symbol lookups must be rejected.
  expect_error(.Call("sk_ffi_version", PACKAGE = "sciencekitr"))
  expect_error(.Call("c_sciencekit_version", PACKAGE = "sciencekitr"))
  expect_error(.Call("C_sciencekit_version", PACKAGE = "sciencekitr"))
})

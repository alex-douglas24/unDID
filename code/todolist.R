#to do reproducibility 
# re run the whole pipeline on a different machine, and check that the output is identical without manual intervention 
# fix the .XPT files paths as right now it is hard coded to my machine, and the output paths are also hard coded to my machine.
#  Move the undid paths into 00_config.R so they aren't redefined per script:  undid_common_dir    <- file.path(clean_dir, "undid", "common")
  #    undid_staggered_dir <- file.path(clean_dir, "undid", "staggered")
  # Keep the common and staggered specs in separate folders. Stage three reads every file in a directory beginning filled_diff_df_, so mixing them would  combine two different specifications.
  # Appendix stuff: final wt is carried but undid stage 2 is unweighted mean no survey weight 
  # 2018 is partial treated year cuz oct 2018 was the legalization date, so the estimate is attenuated.
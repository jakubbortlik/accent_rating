Accent Rating
-------------

This is a collection of scripts and data I used when working on my dissertation.

PsyToolkit (v3.2.0)
-------------------
* `survey.sur` - PsyToolkit survey for collecting metadata and running the
  experiment
* `rating_experiment.psy` - The experiment itself
* `scale_l_to_r.txt` - Code that draws a sliding scale in
  `rating_experiment.psy` with left-to-right orientation
* `scale_r_to_l.txt` - Code that draws a sliding scale in
  `rating_experiment.psy` with right-to-left orientation
* `sounds.txt` - List of audio files used in the experiment (audio files are not
  included due to license limitations)
* bitmaps/ - Collection of pictures used in `rating_experiment.psy`
* tables/ - Collection of sounds used in `rating_experiment.psy`. Each table has
  three columns: variable name, file name, duration

EER measurements
----------------
* `measure_EER.py` - script that draws DET curves and calculates EER values from
  the `sid_results_table_individual_files_filtered.csv` results table. Simply
  run `python measure_EER.py`. The script creates a folder named
  EER_measurements which contains temporary files to verify that same and
  different speaker labels are correct.
* `sid_results_table_individual_files_filtered.csv` - different-sex recordings
  have been filtered out

Language identification
-----------------------
* `phonexia_lid_wrapper.sh` - wrapper for the Phonexia LID technology (this is
  mainly here to show which subset of languages was used in the analysis)
* `speechbrain_lid_wrapper.py` - wrapper for the SpeechBrain LID technology it
  subclasses the EncoderClassifier to extract scores for English and Czech apart
  from the best-matching language (the audio files are not included due to
  license limitations so the script does not really produce the results!)

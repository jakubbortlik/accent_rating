Accent Rating
-------------

This is a collection of scripts and data I used when working on my dissertation.

Recording procedure (Praat directory)
---------------------------
* recording_procedure.praat - this is the script I used for collecting the audio
  data (it's a mess like most Praat scripts I've written, but it was good enough
  to do what I wanted)

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
* `phonexia_lid_wrapper.sh` - wrapper for the Phonexia `LID` technology (this is
  mainly here to show which subset of languages was used in the analysis)
* `speechbrain_lid_wrapper.py` - wrapper for the SpeechBrain `LID` technology it
  subclasses the EncoderClassifier to extract scores for English and Czech apart
  from the best-matching language (the audio files are not included due to
  license limitations so the script does not really produce the results!)

Speaker identification
----------------------
* `sid4_wrapper.sh` - wrapper for the Phonexia `SID4` technology. A simple helper
  script which extracts voiceprints from all wave files in one directory and
  then compares all voiceprints with each other. It also saves the amount of
  "net speech" in each voiceprint to a file.
* `speechbrain_sid_wrapper.py` - a wrapper for SpeechBrain's `SpeakerRecognition`.
  It has options for computing embeddings from audio files or loading previously
  created embeddings. It subclasses `SpeakerRecognition` in order to be able to
  perform verification on embeddings instead of on audio files.
  The script creates embeddings from all audio files in a directory and then
  performs speaker verification either on  all combinations or all permutations
  of the embeddings set.

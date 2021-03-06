#
#     Collect Data: A Praat script for the creation of a sound corpus
#
#     Copyright (R) 2019 Jakub F. Bortlík
#     All Rights Reserved
#
#     This program is free software; you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation; either version 2 of the License, or
#     (at your option) any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#     If you wish to contact the author you can do so here:
#     jakub.bortlik(at)gmail.com
#
#     AUTHOR: Jakub Bortlík <jakub.bortlik@gmail.com>
#     REVISION: 2019-10-10, 13:00 p.m.
#
#     README

################################################################################
### global variables
################################################################################
# File names of the langauge table.
if windows
	slash$ = "\"
elsif unix
	slash$ = "/"
endif
langTab$ = "languages.csv"
questionnaire$ = "questionnaire.csv"
stimuli$ = "stimuli"
speakers$ = "speakers"
if !fileReadable (speakers$)
	createDirectory: speakers$
endif
# ii is the N'th repetition of a text prompt.
ii = 0
task = 0
second = 0
allowNextAfter = 0
allowNext = 0
skipBefore = 0
buttonActive = 1
selfService = 0
internalRecorder = 1
nativeSpeaker = 1
nativeLanguage$ = "English"
beep = 0
debug = 0
sec = 1
if debug > 1
	sec = 0.1
endif
paused = 0
enablePause = 0
enableSkip = 0
missingProficiency = 0
wrongCharacter = 0
other_langs$ = ""
practiceRound = 0; if practiceRound = 1, the message is shown on the screen
bgColor$ = "White"
maximized = 0; the Demo window is not maximized at the beginning

# Create the beep sound to mark beginning and end of annotation.
if not selfService and not internalRecorder
	beep = Create Sound as pure tone: "beep", 1, 0, 0.2, 44100, 440, 0.3, 0.01, 0.01
endif


################################################################################
# START OF PROCEDURE SECTION
################################################################################

# Mark the Practice round clearly on top of the page.
procedure WRITE_PRACTICE_ROUND
	demo Font size: 50
	demo Red
	demo Text: 50, "centre", 92, "bottom", "Practice round"
	demoShow ( )
	demo Font size: 24
	demo Black
endproc

# Paint the "count up" and stimulus count.
procedure WRITE_COUNTS
	demo Select inner viewport: 0, 100, 0, 100
	demo Paint rectangle: bgColor$, 85, 100, 90, 100
	demo Text: 98, "right", 95, "half", "'second'/'maxSeconds'"
	if task = 3
		demo Text: 98, "right", 5, "half", "'stim'/'nStim'"
	else
		demo Text: 98, "right", 5, "half", "'i'/'nStimuli'"
	endif
	demoShow ( )
endproc

# Draw the continue button in the right colour and with the right text.
procedure DRAW_CONTINUE_BUTTON
	if maximized = 1
		demo Select inner viewport: 0, 100, 0, 100
	else
		demo Select inner viewport: 0, 100, 2.5, 100
	endif
	if buttonActive = 1 or paused = 1 or (enableSkip = 1 and allowNext > 0)
		demo Paint rounded rectangle: 0.6, 38, 62, 2, 8, 5
	else
		demo Paint rounded rectangle: 0.9, 38, 62, 2, 8, 5
		demo Grey
	endif
	if enableSkip = 1 and allowNext > 0
		demo Text: 50, "centre", 5, "half", "Press SPACE to skip ('allowNext')"
	else
		demo Text: 50, "centre", 5, "half", "Press SPACE to continue"
	endif
	demo Black
	demo Select inner viewport: 0, 100, 0, 100
	demoShow ( )
endproc

# Draw the item.
procedure DRAW_STIMULI_SCREEN
	demo Erase all
	if practiceRound = 1
		@WRITE_PRACTICE_ROUND
	endif
	if task = 1
		demo Text: 50, "centre", 70, "half", "Tell your friend in ##'lang$'#:"
		demo Text: 50, "centre", 50, "half", stim$
	elsif task = 2
		if index (stim$, ".png") = 0
			stim$ = stim$ + ".png"
		endif
		# The pictures with "hor" in their name are double the width than those
		# without, so adjust the viewport accrodingly.
		if rindex (stim$, "_hor_") > 0
			demo Select inner viewport: 2, 98, 4, 96
		else
			demo Select inner viewport: 16, 84, 10, 98
		endif
		if practiceRound = 1
			picture_path$ = stimuli$ + slash$ + "pictures" + slash$ + stim$
			demo Insert picture from file: picture_path$, 0, 100, 0, 100
		else
			picture_path$ = stimuli$ + slash$ + session_stimuli$ + slash$ + stim$
			demo Insert picture from file: picture_path$, 0, 100, 0, 100
		endif
		demo Select inner viewport: 0, 100, 0, 100
		demo Text: 50, "centre", 95, "half", "Tell your friend in ##'lang$'# about the pictures:"
	elsif task = 3
		demo Text: 50, "centre", 70, "half", "Tell your friend in ##'lang$'# what you think about:"
		demo Font size: 50
		demo Text: 50, "centre", 50, "half", stim$
		demo Font size: 24
	endif
endproc

procedure DRAW_PAUSE_BUTTON
	demo Select inner viewport: 0, 100, 0, 100
	demo Paint rounded rectangle: 0.6, 64, 72, 2, 8, 5
	demo Text: 68, "centre", 5, "half", "%#Pause"
	demoShow ( )
endproc

# Wait for user input and pause the script by pressing "p".
procedure ENABLE_PAUSE: pauseLength, sleepLength
	enablePause = 1
	if task = 3 and (second < skipBefore) and nStimuli < (200 - 1) and allowNext > 0
		enableSkip = 1
	endif
	buttonActive = 0
	@DRAW_PAUSE_BUTTON
	@DRAW_CONTINUE_BUTTON
	for pauseSec to pauseLength
		# Be ready for the user pausing the script
		demoPeekInput ( )
			# Show the pause screen
			if demoKey$ ( ) = "p" or demoClickedIn (64, 72, 2, 8)
				@PAUSED_SCREEN
				@DRAW_PAUSE_BUTTON
			endif
		sleep (sleepLength)
	endfor
	buttonActive = 1
	paused = 0
	enablePause = 0
endproc

# Extend the textgrid by the time elapsed from the last update and insert label.
procedure UPDATE_GRID: label$
	interval = stopwatch
	nIntervals += 1
	selectObject: grid
	Extend time: interval, "End"
	Set interval text: 1, nIntervals, label$
	Save as text file: grid$
endproc

# Show individual senteces on the screen.
procedure PRESENT_TEXT
	for i to nStimuli
		for ii to 2
			label AFTER_PAUSED_TEXT

			# Draw individual stimuli and the Next and Pause buttons.
			selectObject: stimList
			stim$ = Get string: i
			@DRAW_STIMULI_SCREEN
			@DRAW_CONTINUE_BUTTON
			@DRAW_PAUSE_BUTTON

			# Show the "count up".
			for second from 0 to maxSeconds
				# Sleep for one second between counts.
				# Be ready for user input.
				# "SPACE" go to next stimulus,
				# "w" quit the script completely,
				# "q" skip a TASK,
				# "p" pause the script.
				demoPeekInput ( )
					# Go to next stimulus.
					if demoKey$ ( ) = " " or demoClickedIn (38, 62, 2, 8)
						goto NEXT_TEXT
					endif
					# Quit the script gracefully.
					if demoKey$ ( ) = "w"
						if practiceRound = 0
							@UPDATE_GRID: "SCRIPT QUIT, task 'task', stimulus 'i', second 'second'"
						endif
						goto QUIT_SCRIPT
					endif
					# Skip the text task.
					if demoKey$ ( ) = "q"
						if practiceRound = 0
							@UPDATE_GRID: "TASK SKIPPED, task 'task', stimulus 'i', second 'second'"
						endif
						goto SKIP_TEXT_TASK
					endif
					# Pause the script.
					if demoKey$ ( ) = "p" or demoClickedIn (64, 72, 2, 8)
						@PAUSED_SCREEN
						second -= 1
					endif
				# Paint the "count up" and stimulus count.
				@WRITE_COUNTS
				# Sleep for one second between counts.
				sleep (sec)
			endfor
			label NEXT_TEXT

			# Short pause between individual stimuli.
			demo Erase all
			@DRAW_PAUSE_BUTTON
			buttonActive = 0
			@DRAW_CONTINUE_BUTTON
			@UPDATE_GRID: "'ii'. 'stim$'"
			if practiceRound = 1
				@WRITE_PRACTICE_ROUND
			endif
			# Enable longer pause.
			@ENABLE_PAUSE: 3, 0.1
		endfor
	endfor
	label SKIP_TEXT_TASK
	removeObject: stimList
endproc

# Show individual pictures or topics on the screen.
procedure PRESENT_STIMULI
	stim = 0
	nStim = nStimuli
	for i to nStimuli
		stim += 1
		label PREVIOUS
		demo Erase all

		# Draw individual stimuli and the Next and Pause buttons.
		selectObject: stimList
		if task = 2 or (task = 3 and practiceRound = 1)
			stim$ = Get string: i
		elsif task = 3
			columnIndex = Get column index: lang$
			if columnIndex > 1
				stim$ = Get value: i, lang$
			else
				stim$ = Get value: i, "English"
			endif
		endif

		@DRAW_STIMULI_SCREEN

		# Show the "count up".
		for second from 0 to maxSeconds
			if second > allowNextAfter
				buttonActive = 1
			else
				buttonActive = 0
			endif
			if task = 3 and (second < skipBefore) and nStimuli < (200 - 1) and allowNext > 0
				enableSkip = 1
			endif
			if second > skipBefore
				enableSkip = 0
			endif
			@DRAW_CONTINUE_BUTTON
			@DRAW_PAUSE_BUTTON

			# Be ready for user input.
			# "SPACE" go to next stimulus,
			# "w" quit the script completely,
			# "q" skip a TASK,
			# "p" pause the script.
			demoPeekInput ( )
				# Go to the next item with Right Arrow after 'allowNextAfter' seconds
				if (demoKey$ ( ) = " " or demoClickedIn (38, 62, 2, 8) )
					... and ((second > allowNextAfter ) or (second < skipBefore + 2))
					... and (allowNext > 0 or second > allowNextAfter)
					if second < skipBefore + 2
						stim -= 1
						allowNext -= 1
					endif
					if task = 3 and nStimuli < (200 - 1) and second < skipBefore + 2
						enableSkip = 1
						stim$ = "SKIPPED - " + stim$
						nStimuli += 1
						buttonActive = 0
					endif
					goto NEXT
				elif demoKey$ ( ) = "←" and i > 1
					i -= 1
					goto PREVIOUS
				endif
				# Quit the script gracefully.
				if demoKey$ ( ) = "w"
					if practiceRound = 0
						@UPDATE_GRID: "SCRIPT QUIT, task 'task', stimulus 'i', second 'second'"
					endif
					goto QUIT_SCRIPT
				endif
				# Skip the task.
				if demoKey$ ( ) = "q"
					if practiceRound = 0
						@UPDATE_GRID: "TASK SKIPPED, task 'task', stimulus 'i', second 'second'"
					endif
					goto SKIP_TASK
				endif
				# Pause the script.
				if demoKey$ ( ) = "p" or demoClickedIn (64, 72, 2, 8)
					@PAUSED_SCREEN
					second -= 1
				endif

			# Paint the "count up" and stimulus count.
			@WRITE_COUNTS
			# sleep for one second between counts
			sleep (sec)
		endfor

		label NEXT

		# Short pause after a stimulus enabling longer pause.
		demo Erase all
		@DRAW_PAUSE_BUTTON
		buttonActive = 0
		enablePause = 1
		if task = 3 and (second < skipBefore) and nStimuli < (200 - 1) and allowNext > 0
			enableSkip = 1
		endif
		@DRAW_CONTINUE_BUTTON
		buttonActive = 1
		@UPDATE_GRID: stim$
		if practiceRound = 1
			@WRITE_PRACTICE_ROUND
		endif
		# Enable longer pause.
		if i < nStimuli
			if debug > 4
				@ENABLE_PAUSE: 1, 0.1
			else
				@ENABLE_PAUSE: 10, 0.1
			endif
		endif
	endfor
	label SKIP_TASK

	# Remove the items from the stimuli list.
	selectObject: stimList
	if task = 2 or task = 3
		for r to nStimuli
			if task = 3 and practiceRound = 0
				Remove row: 1
			else
				Remove string: 1
			endif
		endfor
		if task = 2 and practiceRound = 0
			Save as raw text file: speakerPath$ + slash$ + session_stimuli$ + "_" + string$(session) + ".txt"
		elsif task = 3 and practiceRound = 0
			Save as tab-separated file: speakerPath$ + slash$ + session_stimuli$ + ".csv"
		endif
	endif
	removeObject: stimList
endproc

# Wait for user input to continue with the script.
procedure SPACE_TO_CONTINUE: updateGrid$
	@DRAW_CONTINUE_BUTTON
	while demoWaitForInput ( )
		# enable quitting the script immediately.
		if demoKey$ ( ) = "w"
			goto QUIT_SCRIPT
		endif
		if demoKey$ ( ) = " " or demoClickedIn (38, 62, 2, 8)
			goto CONTINUE
		endif
	endwhile
	label CONTINUE
	@UPDATE_GRID: updateGrid$
endproc

# Show the error message if the "Other languages" names contain some mistakes.
procedure WRONG_OTHER_LANGS
	beginPause: "Mistake in other languages"
		if missingProficiency > 0
			if missingProficiency = 1
				missing_prof$ = lang_prof$
			elsif missingProficiency = 2
				missing_prof$ = other_languages$
			endif
			comment: "You didn't specify valid proficiency for language: " + missing_prof$
		endif
		pr$ = ""
		if wrongCharacter > 0
			if wrongCharacter = 1
				wrongChar$ = lang_prof$
				pr$ = right$ (lang_prof$, 1)
			elsif wrongCharacter = 2
				wrongChar$ = other_languages$
				pr$ = right$ (other_languages$, 1)
			endif
			if missingProficiency = 0
				wrongChar$ = wrongChar$ - pr$
			endif
			comment: "The language name must begin with a letter: " + wrongChar$
		endif
	clicked = endPause: "Continue", 1, 1
endproc

# Show the error message if the Usage of languages is not specified correctly.
procedure WRONG_USAGE
	beginPause: "Wrong usage"
		comment: "You didn't specify the weekly usage correctly:"
		if wrong_usage = 1
			comment: "The sum cannot be more than 100!"
		elsif wrong_usage = 2
			comment: "The estimated usage cannot be less than 0!"
		elsif wrong_usage = 3
			comment: "The estimated usage should not be 0."
		else 
			comment: "The sum cannot be more than 100."
		endif
	clicked = endPause: "Continue", 1, 1
endproc

# Create the textgrid.
procedure CREATE_GRID: gridCount
	# Save (and remove) the previous grid.
	if gridCount > 1
		selectObject: grid
		Save as text file: grid$
	endif

	# Create the TextGrid for the recording.
	grid_length = 0
	nIntervals = 1
	# Get time from the first stopwatch.
	if gridCount = 1
		firstInterval = stopwatch
	else
		firstInterval = 0.0001
		stopwatch
	endif
	grid = Create TextGrid: 0, firstInterval, "stimulus", ""
	# The first grid captures the time it took to fill in the questionnaires.
	if gridCount = 1
		selectObject: grid
		if session = 1
			Set interval text: 1, 1, "Personal information"
		else
			Set interval text: 1, 1, "Speaker selection"
		endif
		Rename: speaker$ + "_session_" + string$ (session) + "_instructions"
		grid$ = sessionPath$ + "_instructions.TextGrid"
		Save as text file: grid$
	# The other textgrids contain annotations.
	else
		selectObject: grid
		Rename: speaker$ + "_session_" + string$ (session)
		grid$ = sessionPath$ + ".TextGrid"
		Save as text file: grid$
	endif
endproc

procedure EXPLAIN_TASK_1_1
	demo Erase all
	if practiceRound = 1
		@WRITE_PRACTICE_ROUND
	endif
	demo Text: 50, "centre", 70, "half", "Task 1 - full text:"
	demo Text: 50, "centre", 60, "half", "First have a look at the following 'lang$' text."
	demo Text: 50, "centre", 50, "half", "You can go through it several times to get familiar with it."
	demo Text: 50, "centre", 40, "half", "Speak aloud and practice any difficult parts."
endproc

procedure EXPLAIN_TASK_1_2
	demo Erase all
	if practiceRound = 1
		@WRITE_PRACTICE_ROUND
	endif
	demo Text: 50, "centre", 80, "half", "Task 1 - individual sentences:"
	demo Text: 50, "centre", 70, "half", "Imagine you are telling a story in 'lang$' to a friend on the phone."
	demo Text: 50, "centre", 60, "half", "Say the 'lang$' sentences aloud in a natural voice."
	demo Text: 50, "centre", 50, "half", "You'll see each sentence two times. Please, say it each time."
	demo Text: 50, "centre", 40, "half", "It's important to press the ""continue"" button AFTER you finished reading the sentence."
	demo Text: 50, "centre", 30, "half", "You can pause the script by pressing ""P"" or clicking the ""Pause"" button."
	demo Text: 50, "centre", 20, "half", "If you make a mistake or hesitate, just read the sentence once more."
endproc

procedure EXPLAIN_TASK_2
	demo Erase all
	if practiceRound = 1
		@WRITE_PRACTICE_ROUND
		demo Text: 50, "centre", 30, "half", "In the actual recording you'll have more time and more pictures."
	endif
	demo Text: 50, "centre", 80, "half", "Task 2 - Pictures:"
	demo Text: 50, "centre", 70, "half", "Imagine you are talking in 'lang$' to a friend on the phone."
	demo Text: 50, "centre", 60, "half", "Describe in detail %%differences% and %%similarities% in the 'nStimuli' pairs of pictures."
	demo Text: 50, "centre", 50, "half", "You'll have 'maxSeconds' seconds to discribe each pair of pictures."
	demo Text: 50, "centre", 40, "half", "You can go to the next pair after 'allowNextAfter' seconds if you don't know what to say more."
endproc

procedure EXPLAIN_TASK_3
	demo Erase all
	if practiceRound = 1
		@WRITE_PRACTICE_ROUND
		demo Text: 50, "centre", 40, "half", "In the actual recording you'll have more time and more topics."
		demo Text: 50, "centre", 30, "half", "If you don't know what to say about a topic at all,"
		demo Text: 50, "centre", 20, "half", "you can skip 'allowNext' of them within the first 'skipBefore' seconds."
	else
		demo Text: 50, "centre", 40, "half", "If you don't know what to say about a topic at all,"
		demo Text: 50, "centre", 30, "half", "you can skip 'allowNext' of them within the first 'skipBefore' seconds."
	endif
	demo Text: 50, "centre", 80, "half", "Task 3 - Topics:"
	demo Text: 50, "centre", 70, "half", "Imagine you are talking in 'lang$' to a friend on the phone."
	demo Text: 50, "centre", 60, "half", "Tell him or her what you think about the following 'nStimuli' topics."
	demo Text: 50, "centre", 50, "half", "You'll have 'maxSeconds' seconds for each topic. You can go to the next after 'allowNextAfter' seconds."
endproc

# Redraw the creen if script is paused - hide the stimulus, and wait for input.
procedure PAUSED_SCREEN
	if enablePause = 0
		if task = 1
			@UPDATE_GRID: "'ii'. 'stim$' - PAUSED"
		else
			@UPDATE_GRID: "'stim$' - PAUSED"
		endif
	endif
	paused = 1

	# Backup some variable values.
	enSkip = 0
	if enableSkip = 1
		enSkip = 1
	endif
	enableSkip = 0
	enablePause = 0
	butActive = 0
	if buttonActive = 1
		butActive = 1
	else
		butActive = 0
	endif
	buttonActive = 1

	demo Select inner viewport: 0, 100, 0, 100
	if practiceRound = 1
		@WRITE_PRACTICE_ROUND
	endif

	# Hide the Pause button and write "Paused" instead.
	demo Paint rounded rectangle: bgColor$, 64, 72, 2, 8, 5
	demo Red
	demo Text: 68, "centre", 5, "half", "%%Paused%"
	demo Black

	# Hide the Stimulus.
	if task = 2
		if rindex (stim$, "_hor_") > 0
			demo Select inner viewport: 2, 98, 4, 88
		else
			demo Select inner viewport: 16, 84, 10, 98
		endif
		demo Paint rectangle: bgColor$, 0, 100, 0, 100
		demo Select inner viewport: 0, 100, 0, 100
	else
		demo Paint rectangle: bgColor$, 16, 84, 10, 98
	endif

	@SPACE_TO_CONTINUE: "PAUSE"

	# Hide the "Paused" text.
	demo Paint rectangle: bgColor$, 63, 73, 2, 8

	# Revert the variables for the Continue Button.
	paused = 0
	if enSkip = 1
		enableSkip = 1
	endif
	if butActive = 1
		buttonActive = 1
	else
		buttonActive = 0
	endif

	# Redraw the screen after Pause.
	@DRAW_STIMULI_SCREEN
	@DRAW_CONTINUE_BUTTON
	@DRAW_PAUSE_BUTTON
endproc

################################################################################
# END OF PROCEDURE SECTION
################################################################################


################################################################################
### Select the session and specify personal data.
################################################################################

label SELECT_SESSION
if nativeSpeaker
	session = 1
else
	beginPause: "Select session"
		comment: "Which session are you doing now?"
	session = endPause: "1", "2", "3", "Cancel", 1, 4
	if session = 4
		goto CANCEL
	endif
endif

# Start measuring time of form filling.
stopwatch

# In session one: show a number of questionnaires and create the stimuli lists
if session = 1
	# Show the initial form for selection of Nickname, Sex, Age
	nickname$ = "Jane_Doe"
	sex = 1
	age = 0
	i_agree_with_the_University_consent = 1
	i_agree_with_the_Phonexia_consent = 1
	highest_level_of_education_completed_so_far = 3
	field_of_study_or_profession$ = ""
	disorders$ = "none"
	label CHOOSE_NICKNAME
	beginPause: "Specify your personal information"
		comment: "Please, specify your personal information."
		comment: "Nickname, sex and age are required."
		sentence: "Nickname", nickname$
		choice: "Sex", sex
			option: "Female"
			option: "Male"
		integer: "Age", age
		optionMenu: "Highest level of education completed so far", highest_level_of_education_completed_so_far
			option: "None"
			option: "Primary"
			option: "Secondary"
			option: "Bachelor"
			option: "Master"
			option: "PhD"
		comment: "If you are studying at university or employed please specify:"
		sentence: "Field of study or profession", field_of_study_or_profession$
		comment: "Specify any speech or hearing disorders:"
		sentence: "Disorders", disorders$
		comment: "Before you continue, please read Consent_form_Palacky_University.pdf"
		comment: "and Consent_audio_recordings_Phonexia.pdf in the folder 01_recording."
		comment: "It is necessary to agree with the University consent."
		comment: "You don't have to give your consent for Phonexia."
		boolean: "I agree with the University consent", i_agree_with_the_University_consent
		boolean: "I agree with the Phonexia consent", i_agree_with_the_Phonexia_consent
	clicked = endPause: "Cancel", "Next", 2, 1

	# Check that the speaker code is OK and create the Questionnaire table.
	if clicked = 1
		goto CANCEL
	else
		# Add the current date to the speaker code.
		d$ = date$ ( )
		timestamp$ = right$ (d$, 4) + "-" + mid$ (d$, 5, 3) + "-" + mid$ (d$, 9, 2)
		timestamp$ = replace$ (timestamp$, " ", "0", 0)
		speaker_id$ = nickname$ + "_" + sex$ + "_" + string$ (age)
		speaker$ = speaker_id$ + "_" + timestamp$
		speakerPath$ = speakers$ + slash$ + speaker$
		if fileReadable (speakerPath$ + slash$ + langTab$) and debug = 0
			beginPause: "Speaker already exists"
				comment: "This combination of speaker nickname, sex and age already exists:"
				comment: speaker_id$
				comment: "Please, choose a different nickname or select a different session for an existing speaker."
			clicked = endPause: "Cancel", "Change nickname", "Select session", 2, 1
			if clicked = 1
				goto CANCEL
			elsif clicked = 2
				goto CHOOSE_NICKNAME
			else
				goto SELECT_SESSION
			endif
		else
			createDirectory: speakerPath$
		endif
		questionnaire = Create Table with column names: "questionnaire", 17, "question answer"
		Set string value: 1, "question", "nickname"
		Set string value: 1, "answer", nickname$
		Set string value: 2, "question", "sex"
		Set string value: 2, "answer", sex$
		Set string value: 3, "question", "age"
		Set string value: 3, "answer", string$ (age)
		Set string value: 4, "question", "date_of_session_1"
		Set string value: 4, "answer", timestamp$
		Set string value: 5, "question", "date_of_session_2"
		Set string value: 5, "answer", ""
		Set string value: 6, "question", "date_of_session_3"
		Set string value: 6, "answer", ""
		Set string value: 7, "question", "speaker_folder"
		Set string value: 7, "answer", shellDirectory$ + slash$ + speakers$ + slash$ + speaker$
		Set string value: 8, "question", "completed_education"
		Set string value: 8, "answer", highest_level_of_education_completed_so_far$
		Set string value: 9, "question", "field_of_study_or_profession"
		Set string value: 9, "answer", field_of_study_or_profession$
		Set string value: 10, "question", "speech_or_hearing_disorders"
		Set string value: 10, "answer", disorders$
		Set string value: 11, "question", "consent_University"
		Set numeric value: 11, "answer", i_agree_with_the_University_consent
		Set string value: 12, "question", "consent_Phonexia"
		Set numeric value: 12, "answer", i_agree_with_the_Phonexia_consent
	endif

	# Set variables for saving recordings and textgrids.
	speakerRecPath$ = speakerPath$ + slash$ + "recordings"
	sessionPath$ = speakerRecPath$ + slash$ + speaker$ + "_session_" + string$ (session)
	# Create the directory for storing recordings and TextGrids.
	if !fileReadable (speakerRecPath$)
		createDirectory: speakerRecPath$
	endif

	# Create table for languages that will be used.
	nUsedLangs = 0
	langTab = Create Table with column names: langTab$, 0, "language language_used proficiency text_present onset understanding speaking reading writing native_teachers teacher_dialects speaker_dialects native_speakers native_speakers_how_often native_speakers_origin non-native_speakers non-native_speakers_how_often non-native_speakers_origin media media_specific media_how_often media_origin usage"
	languages = Read Strings from raw text file: stimuli$ + slash$ + "languages.txt"
	nLangs = Get number of strings

	# Set the default proficiency to 0 (index 1 in array 0-9)
	for l to nLangs
		langFile$ = Get string: l
		l$ = langFile$ - ".txt"
		ll$ = replace_regex$ (l$, "(^.)", "\l\1", 0)
		'll$' = 1
		l_'l'$ = l$
		ll_'l'$ = ll$
	endfor

	# Create the TextGrid for the annotation.
	@CREATE_GRID: 1

	# Let the Speaker specify experience with languages.
	for group to 3
		label WRONG_OTHER_LANGUAGES
		beginPause: "Specify your experience with languages"
			comment: "Rate your proficiency:"
			comment: "0 = you don't speak the language."
			comment: "9 = you are native or bilingual speaker."
			comment: "You should be able to READ and SPEAK the selected languages"
			# Make a list of available languages.
			# Show all the languages that have an Aesop text file (defined above)
			if group = 1
				comment: "THE ALPHABETICAL LIST CONTINUES ON THE NEXT PAGE (page 'group'/3)."
				fromLang = 1
				toLang = 12
			elsif group = 2
				comment: "THE ALPHABETICAL LIST CONTINUES ON THE NEXT PAGE (page 'group'/3)."
				fromLang = 13
				toLang = 24
			elsif group = 3
				comment: "(page 'group'/3)"
				fromLang = 25
				toLang = 34
			endif
			for l from fromLang to toLang
				selectObject: languages
				langFile$ = Get string: l
				l$ = langFile$ - ".txt"
				ll$ = replace_regex$ (l$, "(^.)", "\l\1", 0)
				# This creates numeric variables in the form of lowercase langauge
				# names whose values can range from 0-5 (0 by default)
				optionMenu: "'l$'", 'll$'
				for o from 0 to 9
					option: string$ (o)
				endfor
			endfor
			if group = 1
				languageButtons$ = """Cancel"", ""Next"", 2, 1"
			elsif group = 2
				languageButtons$ = """Cancel"", ""Back"", ""Next"", 3, 1"
			elsif group = 3
				if missingProficiency > 0
					comment: "YOU DIDN'T SPECIFY PROFICIENCY FOR ONE OF THE LANGUAGES!"
				endif
				if wrongCharacter > 0
					comment: "THE LANGUAGE NAME MUST BEGIN WITH A LETTER!"
				endif
				missingProficiency = 0
				wrongCharacter = 0
				comment: "Specify other languages that you speak, with proficiency from 1-9."
				comment: "E.g., Clingon 7, Sindarin 4"
				sentence: "Other languages", other_langs$
				languageButtons$ = """Cancel"", ""Back"", ""Next"", 3, 1"
			endif
		clicked = endPause: 'languageButtons$'
		if clicked = 1
			goto CANCEL
		elsif clicked = 2
			if group = 2
				group = 0
			elsif group = 3
				group = 1
			endif
		endif
	endfor

	# Add the "other languages" to the table
	other_langs = 0
	if other_languages$ != ""
		other_langs$ = other_languages$
		other_languages$ = replace_regex$ (other_languages$, "\s+", "", 0)
		other_languages$ = replace_regex$ (other_languages$, ";", ",", 0)
		other_languages$ = replace_regex$ (other_languages$, "(^,+)|([-=+_.:?!/])", "", 0)
		other_languages$ = replace_regex$ (other_languages$, ",+", ",", 0)
		other_length = length (other_languages$)
		comma = index (other_languages$, ",")
		while comma > 0 and other_langs < 10
			other_langs += 1
			lang_prof$ = left$ (other_languages$, comma - 1)
			prof_'other_langs'$ = right$ (lang_prof$, 1)
			other_lang_'other_langs'$ = lang_prof$ - prof_'other_langs'$
			if index ("123456789", prof_'other_langs'$) = 0 or index_regex (lang_prof$, "[a-zA-Z]") > 1
				if index ("123456789", prof_'other_langs'$) = 0
					group = 3
					missingProficiency = 1
				endif
				if index_regex (lang_prof$, "[a-zA-Z]") > 1
					group = 3
					wrongCharacter = 1
				endif
				@WRONG_OTHER_LANGS
				goto WRONG_OTHER_LANGUAGES
			endif
			other_languages$ = right$ (other_languages$, other_length - comma)
			other_length = length (other_languages$)
			comma = index (other_languages$, ",")
		endwhile
		other_langs += 1
		prof_'other_langs'$ = right$ (other_languages$, 1)
		other_lang_'other_langs'$ = other_languages$ - prof_'other_langs'$
		if index ("0123456789", prof_'other_langs'$) = 0 or index_regex (other_languages$, "[a-zA-Z]") > 1
			if index ("0123456789", prof_'other_langs'$) = 0
				group = 3
				missingProficiency = 2
			endif
			if index_regex (other_languages$, "[a-zA-Z]") > 1
				group = 3
				wrongCharacter = 2
			endif
			@WRONG_OTHER_LANGS
			goto WRONG_OTHER_LANGUAGES
		endif
	endif

	# Save the Proficiency and Text_present values to the language table.
	for o to other_langs
		nUsedLangs += 1
		selectObject: langTab
		Append row
		Set string value: nUsedLangs, "language", other_lang_'o'$
		prof = number (prof_'o'$) + 1
		Set numeric value: nUsedLangs, "proficiency", prof
		Set string value: nUsedLangs, "text_present", "no"
	endfor

	# Create the list of languages.
	for l to nLangs
		l$ = l_'l'$
		ll$ = ll_'l'$
		# ll$ is the lowercase name of the language, it is also a variable which
		# contains information about proficiency: 'll$' = 1 means the speaker
		# does not speak this language, so only use languages the speaker has
		# selected
		if 'll$' > 1
			nUsedLangs += 1
			selectObject: langTab
			Append row
			Set string value: nUsedLangs, "language", l$
			Set numeric value: nUsedLangs, "proficiency", 'll$'
			Set string value: nUsedLangs, "text_present", "yes"
		endif
	endfor

	# Check that at least one language is selected.
	if nUsedLangs < 1
		beginPause: "No languages selected"
			comment: "Please, select at least one language!"
		clicked = endPause: "Select languages", 1, 1
		group = 1
		goto WRONG_OTHER_LANGUAGES
	endif

	@UPDATE_GRID: "Initial language selection"

	# Sort the language table according to proficiency and language name
	selectObject: langTab
	Sort rows: "proficiency language"
	Reflect rows

	# Ask the speaker to fill in the detailed language questionnaire: Family
	if debug = 2 or debug = 1 or debug = 5
		goto SKIPQUEST
	endif
	usage = 0
	wrong_usage = 0
	country_and_years_of_residence$ = ""
	languages_mother$ = ""
	languages_father$ = ""
	home_languages_mother$ = ""
	home_languages_father$ = ""
	label USAGE_ESTIMATION
	beginPause: "Detailed language questionnaire - family"
		comment: "Where have you lived? Specify COUNTRY and AGE in years:"
		comment: "E.g., England (0-15, 16-20), Narnia (15-16)"
		sentence: "Country and years of residence", country_and_years_of_residence$
		comment: "What languages do/did your parents speak?"
		comment: "Native language first, e.g., Moravian Czech, Swiss German:"
		sentence: "Languages_mother", languages_mother$
		sentence: "Languages_father", languages_father$
		comment: "What languages did your parents speak to YOU at home?"
		sentence: "Home languages_mother", home_languages_mother$
		sentence: "Home languages_father", home_languages_father$
		# Ask about the dialects of the speaker.
		comment: "Specify the dialect(s) that you speak:"
		comment: "E.g., British, Eastern, Standard, Brazilian,..."
		for l to nUsedLangs
			selectObject: langTab
			lang$ = Get value: l, "language"
			lang_usage$ = replace_regex$ (lang$, "(^.)", "\l\1", 0)
			if wrong_usage > 0
				sentence: "What dialects of 'lang$' do you speak", what_dialects_of_'lang$'_do_you_speak$
			else
				sentence: "What dialects of 'lang$' do you speak", ""
			endif
		endfor
		# Estimation of language use.
		comment: "How many percent of your typical week do you use these languages:"
		if wrong_usage = 1
			comment: "THE SUM CANNOT BE MORE THAN 100!"
		elsif wrong_usage = 2
			comment: "THE ESTIMATED USAGE CANNOT BE LESS THAN 0!"
		elsif wrong_usage = 3
			comment: "THE ESTIMATED USAGE SHOULD NOT BE 0."
		else 
			comment: "The sum cannot be more than 100."
		endif
		for l to nUsedLangs
			selectObject: langTab
			lang$ = Get value: l, "language"
			lang_usage$ = replace_regex$ (lang$, "(^.)", "\l\1", 0)
			if wrong_usage > 0
				integer: "'lang$'", 'lang_usage$'
			else
				if nUsedLangs = 1
					usage = 100
				else
					usage = 0
				endif
				integer: "'lang$'", usage
			endif
		endfor
		wrong_usage = 0
	clicked = endPause: "Cancel", "Next", 2, 1
	if clicked = 1
		goto CANCEL
	endif
	# Check that the sum of usage percentages is correct (0 < usage < 100)
	usage = 0
	for l to nUsedLangs
		selectObject: langTab
		lang$ = Get value: l, "language"
		lang_usage$ = replace_regex$ (lang$, "(^.)", "\l\1", 0)
		usage += 'lang_usage$'
	endfor
	if usage > 100 or usage < 0 or usage = 0
		if usage > 100
			wrong_usage = 1
		elsif usage < 0
			wrong_usage = 2
		elsif usage = 0
			wrong_usage = 3
		endif
		@WRONG_USAGE
		goto USAGE_ESTIMATION
	endif
	for l to nUsedLangs
		selectObject: langTab
		lang$ = Get value: l, "language"
		lang_usage$ = replace_regex$ (lang$, "(^.)", "\l\1", 0)
		Set numeric value: l, "usage", 'lang_usage$'
	endfor
	Save as tab-separated file: speakerPath$ + slash$ + langTab$
	# Write the answeres to the Questionnaire.
	selectObject: questionnaire
	Set string value: 13, "question", "country_of_residence"
	Set string value: 13, "answer", country_and_years_of_residence$
	Set string value: 14, "question", "languages_mother"
	Set string value: 14, "answer", languages_mother$
	Set string value: 15, "question", "languages_father"
	Set string value: 15, "answer", languages_father$
	Set string value: 16, "question", "home_languages_mother"
	Set string value: 16, "answer", home_languages_mother$
	Set string value: 17, "question", "home_languages_father"
	Set string value: 17, "answer", home_languages_father$
	Save as tab-separated file: speakerPath$ + slash$ + questionnaire$
	plusObject: languages
	Remove

	@UPDATE_GRID: "Language questionnaire - family and usage"

	# Ask the speaker which languages to use.
	wrongSum = 0
	if nUsedLangs > 1
		label SELECT_LANGUAGES
		beginPause: "Select languages that will be used."
			if wrongSum = 1
				comment: "SELECT AT MOST FOUR LANGUAGES!"
			elsif wrongSum = 2
				comment: "SELECT AT LEAST ONE LANGUAGE!"
			else
				comment: "Select 1-4 languages."
			endif
			comment: "You should be able to READ and SPEAK those languages"
			comment: "which you selected from the alphabetical list."
			comment: "For those that you typed in as ""other languages"","
			comment: "it's enough if you can SPEAK them."
			if nativeSpeaker
				comment: "It's enough to select 'nativeLanguage$' but you can do other languages if you want."
			endif
			wrongSum = 0
			if nUsedLangs >= 4
				for l to 4
					selectObject: langTab
					lang$ = Get value: l, "language"
					if nativeSpeaker and lang$ <> nativeLanguage$
						boolean: lang$, 0
					else
						boolean: lang$, 1
					endif
				endfor
				for l from 5 to nUsedLangs
					selectObject: langTab
					lang$ = Get value: l, "language"
					boolean: lang$, 0
				endfor
			else
				for l to nUsedLangs
					selectObject: langTab
					lang$ = Get value: l, "language"
					if nativeSpeaker and lang$ <> nativeLanguage$
						boolean: lang$, 0
					else
						boolean: lang$, 1
					endif
				endfor
			endif
		clicked = endPause: "Cancel", "Next", 2, 1
		if clicked = 1
			goto CANCEL
		endif
		sumLanguages = 0
		for l to nUsedLangs
			selectObject: langTab
			lang$ = Get value: l, "language"
			lang_value$ = replace_regex$ (lang$, "(^.)", "\l\1", 0)
			sumLanguages += 'lang_value$'
		endfor
		if sumLanguages > 4
			wrongSum = 1
			goto SELECT_LANGUAGES
		elsif sumLanguages < 1
			wrongSum = 2
			goto SELECT_LANGUAGES
		endif
	else
		sumLanguages = 1
		for l to nUsedLangs
			selectObject: langTab
			lang$ = Get value: l, "language"
			lang_value$ = replace_regex$ (lang$, "(^.)", "\l\1", 0)
			'lang_value$' = 1
		endfor
	endif

	# Save the Language_used value to the language table, and sort the table.
	for l to nUsedLangs
		selectObject: langTab
		lang$ = Get value: l, "language"
		lang_value$ = replace_regex$ (lang$, "(^.)", "\l\1", 0)
		Set numeric value: l, "language_used", 'lang_value$'
	endfor
	Sort rows: "language_used proficiency language"
	Reflect rows
	Save as tab-separated file: speakerPath$ + slash$ + langTab$

	@UPDATE_GRID: "Final language selection"


	# Detailed questionnaire for the languages the speaker selected.
	nUsedLangs = sumLanguages
	for l to nUsedLangs
		selectObject: langTab
		lang$ = Get value: l, "language"
		prof = Get value: l, "proficiency"
		beginPause: "Detailed language questionnaire: 'lang$'"
			integer: "Your age when you started learning 'lang$'", 0
			comment: "Specify proficiency: 0 = no knowledge, 9 = native-like knowledge:"
			optionMenu: "How well do you UNDERSTAND 'lang$'", prof
				for i from 0 to 9
					option: string$ (i)
				endfor
			optionMenu: "How well do you SPEAK 'lang$'", prof
				for i from 0 to 9
					option: string$ (i)
				endfor
			optionMenu: "How well can you READ 'lang$'", prof
				for i from 0 to 9
					option: string$ (i)
				endfor
			optionMenu: "How well can you WRITE 'lang$'", prof
				for i from 0 to 9
					option: string$ (i)
				endfor
			optionMenu: "Did you have native 'lang$' teachers at school", 1
				option: "No teachers were native speakers"
				option: "Few teachers were native speakers"
				option: "Some teachers were native speakers"
				option: "Most teachers were native speakers"
				option: "All teachers were native speakers"
			sentence: "What dialects did your 'lang$' teachers speak", ""
			comment: "Do you interact with native 'lang$' speakers?"
			optionMenu: "Native speakers", 6
				option: "Teachers"
				option: "Colleagues"
				option: "Friends"
				option: "Family"
				option: "A combination of the above"
				option: "Nobody"
				option: "Most people I interact with in 'lang$' are native speakers"
				option: "I only interact in 'lang$' with native speakers"
			optionMenu: "Native speakers - how often", 1
				option: "Never"
				option: "Less then 1 hour a week"
				option: "1-2 hours a week"
				option: "3-5 hours a week"
				option: "5-7 hours a week"
				option: "8-14 hours a week"
				option: "More than 14 hours a week"
			sentence: "Native speakers - where are they from", ""
			comment: "Do you interact with non-native 'lang$' speakers?"
			optionMenu: "Non-native speakers", 6
				option: "Teachers"
				option: "Colleagues"
				option: "Friends"
				option: "Family"
				option: "A combination of the above"
				option: "Nobody"
				option: "Most people I interact with in 'lang$' are non-native speakers"
				option: "I only interact in 'lang$' with non-native speakers"
			optionMenu: "Non-native speakers - how often", 1
				option: "Never"
				option: "Less then 1 hour a week"
				option: "1-2 hours a week"
				option: "3-5 hours a week"
				option: "5-7 hours a week"
				option: "8-14 hours a week"
				option: "More than 14 hours a week"
			sentence: "Non-native speakers - where are they from", ""
			comment: "Do you listen to 'lang$' from media and entertainment?"
			optionMenu: "Preferred media and entertainment", 1
				option: "None"
				option: "Movies"
				option: "Songs and radio"
				option: "TV and YouTube"
				option: "More of the above"
				option: "All of the above"
			sentence: "Specify preferred media and entertainment", ""
			optionMenu: "Media and entertainment - how often", 1
				option: "Never"
				option: "Less then 1 hour a week"
				option: "1-2 hours a week"
				option: "3-5 hours a week"
				option: "5-7 hours a week"
				option: "8-14 hours a week"
				option: "More than 14 hours a week"
			sentence: "Media and entertainment - where are they from", ""
		clicked = endPause: "Cancel", "Next", 2, 1
		if clicked = 1
			goto CANCEL
		endif
		selectObject: langTab
		Set numeric value: l, "onset", your_age_when_you_started_learning_'lang$'
		Set string value: l, "understanding", how_well_do_you_UNDERSTAND_'lang$'$
		Set string value: l, "speaking", how_well_do_you_SPEAK_'lang$'$
		Set string value: l, "reading", how_well_can_you_READ_'lang$'$
		Set string value: l, "writing", how_well_can_you_WRITE_'lang$'$
		teachers$ = "did_you_have_native_'lang$'_teachers_at_school"
		Set string value: l, "native_teachers", did_you_have_native_'lang$'_teachers_at_school$
		Set string value: l, "teacher_dialects", what_dialects_did_your_'lang$'_teachers_speak$
		Set string value: l, "speaker_dialects", what_dialects_of_'lang$'_do_you_speak$
		Set string value: l, "native_speakers", native_speakers$
		Set string value: l, "native_speakers_how_often", "'native_speakers_-_how_often$'"
		Set string value: l, "native_speakers_origin", "'native_speakers_-_where_are_they_from$'"
		Set string value: l, "non-native_speakers", "'non-native_speakers$'"
		Set string value: l, "non-native_speakers_how_often", "'non-native_speakers_-_how_often$'"
		Set string value: l, "non-native_speakers_origin", "'non-native_speakers_-_where_are_they_from$'"
		Set string value: l, "media", preferred_media_and_entertainment$
		Set string value: l, "media_specific", specify_preferred_media_and_entertainment$
		Set string value: l, "media_how_often", "'media_and_entertainment_-_how_often$'"
		Set string value: l, "media_origin", "'media_and_entertainment_-_where_are_they_from$'"
		Save as tab-separated file: speakerPath$ + slash$ + langTab$

		@UPDATE_GRID: "Detailed language questionnaire: 'lang$'"
	endfor

	label SKIPQUEST


	# Copy the stimuli list and randomize it
	topics = Read Table from tab-separated file: stimuli$ + slash$ + "topics.csv"
	Randomize rows
	Save as tab-separated file: speakerPath$ + slash$ + "topics.csv"
	Save as tab-separated file: speakerPath$ + slash$ + "topics_original.csv"
	removeObject: topics


	# Create the lists of pictures and randomize them.
	if windows
		ses = Create Strings as tokens: "1 2 3", " "
		lan = Create Strings as tokens: "1 2 3 4 5", " "
	else
		ses = Create Strings as tokens: "1 2 3"
		lan = Create Strings as tokens: "1 2 3 4 5"
	endif
	for c to 3
		strings_'c'$ = ""
	endfor
	picPath$ = "." + slash$ + "stimuli" + slash$ + "pictures.txt"
	picList = Read Strings from raw text file: picPath$
	Randomize
	for mult from 0 to 3
		add = mult * 5
		for g to 5
			selectObject: picList
			label$ = Get string: g + add
			selectObject: ses
			Sort
			Randomize
			for c to 3
				selectObject: ses
				s$ = Get string: c
				string_'g'_'c'$ = label$ + "_" + s$
			endfor
		endfor
		for c to 3
			selectObject: lan
			Sort
			Randomize
			for g to 5
				selectObject: lan
				s$ = Get string: g
				strings_'c'$ += string_'s$'_'c'$ + " "
			endfor
		endfor
	endfor
	for c to 3
		if windows
			str = Create Strings as tokens: strings_'c'$, " "
		else
			str = Create Strings as tokens: strings_'c'$
		endif
		Save as raw text file: speakerPath$ + slash$ + "pictures_'c'.txt"
		Save as raw text file: speakerPath$ + slash$ + "pictures_original_'c'.txt"
		removeObject: str
	endfor
	removeObject: ses
	removeObject: lan
	removeObject: picList

# In sessions 2 and 3, select the appropriate speaker from the "database".
else
	speakerDir$ = chooseDirectory$: "Choose the directory with the speaker data"
	lengthSpeakerDir = length (speakerDir$)
	slash = rindex (speakerDir$, slash$)
	lengthSpeaker = lengthSpeakerDir - slash
	# Set variables for saving recordings and textgrids.
	speaker$ = right$ (speakerDir$, lengthSpeaker)
	speakers$ = speakerDir$ - speaker$
	speakerPath$ = speakers$ + slash$ + speaker$
	speakerRecPath$ = speakerPath$ + slash$ + "recordings"
	sessionPath$ = speakerRecPath$ + slash$ + speaker$ + "_session_" + string$ (session)
	langFilePath$ = speakerDir$ + slash$ + langTab$

	# Check that the language table exists.
	# In case any changes were made in the table: sort it according to
	# language_used and proficiency
	if fileReadable (langFilePath$)
		langTab = Read Table from tab-separated file: langFilePath$
		Sort rows: "language_used proficiency language"
		Reflect rows
		allLanguages = Get number of rows
		nUsedLangs = 0
		for l to allLanguages
			selectObject: langTab
			nUsedLangs += Get value: l, "language_used"
		endfor
	else
		exitScript: "Error: No language table available for speaker ", speaker$, "!"
	endif

	# Check that the topic list exists.
	if !fileReadable (speakerPath$ + slash$ + "topics.csv")
		exitScript: "Error: No topics list available for speaker ", speaker$, "!"
	endif

	# Check that the questionnaire exists.
	if !fileReadable (speakerPath$ + slash$ + questionnaire$)
		exitScript: "Error: No language questionnaire available for speaker ", speaker$, "!"
	endif
	d$ = date$ ( )
	timestamp$ = right$ (d$, 4) + "-" + mid$ (d$, 5, 3) + "-" + mid$ (d$, 9, 2)
	questionnaire = Read Table from tab-separated file: speakerPath$ + slash$ + questionnaire$
	if session = 2
		Set string value: 5, "answer", timestamp$
	elsif session = 3
		Set string value: 6, "answer", timestamp$
	endif
	Save as tab-separated file: speakerPath$ + slash$ + questionnaire$
	Remove

	# Create the TextGrid for the instructions.
	@CREATE_GRID: 1
endif


# show the demo window.
demo Axes: 0, 100, 0, 100
demo Font size: 24
demo Black


# Prepare the demo window for presentation.
maximized = 0
demo Erase all
demo Text: 50, "centre", 70, "half", "Maximize the window."
demo Text: 50, "centre", 50, "half", "Press SPACE or click the button at the bottom to continue."
demoShow ( )
@SPACE_TO_CONTINUE: "Maximized window"
maximized = 1


# General info about the tasks.
demo Erase all
if session = 1
	demo Text: 50, "centre", 70, "half", "You are going to do three different tasks:"
	if selfService
		demo Text: 50, "centre", 50, "half", "First, you will get familiar with the different tasks."
		demo Text: 50, "centre", 40, "half", "The examples will be presented in the fictional Klingon language."
		demo Text: 50, "centre", 30, "half", "After that, you will do the tasks in the language(s) that you selected earlier."
	else
		demo Text: 50, "centre", 50, "half", "You will practice the different tasks now with the help of the assistant."
	endif
else
	demo Text: 50, "centre", 70, "half", "You are going to do the same three tasks as in the previous session:"
endif
demo Text: 50, "centre", 60, "half", "%%Reading%, %%picture description%, and %%spontaneous speech% based on various topics."
demoShow ( )
@SPACE_TO_CONTINUE: "Three tasks description."


# Practice round with all three different tasks in the first session.
if debug > 2
	goto SKIP_PRACTICE
endif
label PRACTICE_ROUND
if session = 1
	practiceRound = 1
	lang$ = "Klingon"
	# Explain the task.
	demo Erase all
	@WRITE_PRACTICE_ROUND
	demo Text: 50, "centre", 70, "half", "Part 1"
	demo Text: 50, "centre", 60, "half", "Do the three tasks in the following language:"
	demo Font size: 50
	demo Text: 50, "centre", 45, "half", lang$
	demo Font size: 24
	@SPACE_TO_CONTINUE: "PRACTICE: Part 1"

	############################################################################
	# PRACTICE ROUND
	# TASK I: Reading
	############################################################################
	task = 1
	maxSeconds = 15
	# Explain the task.
	@EXPLAIN_TASK_1_1
	@SPACE_TO_CONTINUE: "PRACTICE: Task 1_1 - instructions"
	# Create the stimuli list
	stimList = Read Strings from raw text file: stimuli$ + slash$ + "aesop" + slash$ + lang$ + ".txt"
	nStimuli = Get number of strings
	# Show the full text.
	demo Erase all
	@WRITE_PRACTICE_ROUND
	for t to nStimuli
		selectObject: stimList
		text$ = Get string: t
		y_axis = 70 - (t * 8)
		demo Text: 50, "centre", y_axis, "half", text$
	endfor
	@SPACE_TO_CONTINUE: "PRACTICE: Full text"
	# Explain the task.
	@EXPLAIN_TASK_1_2
	@SPACE_TO_CONTINUE: "PRACTICE: Task 1_2 - instructions"
	@PRESENT_TEXT

	################################################################################
	# PRACTICE ROUND
	# TASK II: Semi-spontaneous tasks
	################################################################################
	# Each task has different "if's" in the PRESENT_STIMULI procedure.
	task = 2
	# Set the maximum time for which the user can see an item.
	maxSeconds = 20
	# Allow the user to go to the next item after 'allowNextAfter' seconds.
	allowNextAfter = 10;				# allow after this many seconds
	# Don't allow users to skip items.
	skipBefore = -1
	# The user is allowed to show only a certain number of new topics.
	allowNext = maxSeconds
	# Load the picture stimuli list
	session_stimuli$ = "stimuli" + slash$ + "practice_pictures.txt"
	stimList = Read Strings from raw text file: session_stimuli$
	nStimuli = Get number of strings
	# Explain the task
	@EXPLAIN_TASK_2
	@SPACE_TO_CONTINUE: "PRACTICE: Task 2 - instructions"
	@PRESENT_STIMULI

	################################################################################
	# PRACTICE ROUND
	# TASK III: Spontaneous tasks - talk about topics
	################################################################################
	# Each task has different "if's" in the PRESENT_STIMULI procedure.
	task = 3
	# Set the maximum time for which the user can see an item.
	maxSeconds = 20
	# Allow the user to go to the next item after 'allowNextAfter' seconds.
	allowNextAfter = 10;				# = 0, allow this immediately
	# Allow users to skip items.
	skipBefore = 5
	# The user is allowed to skip only a certain number of stimuli.
	allowNext = 5
	# Load the list of topics.
	session_stimuli$ = "stimuli" + slash$ + "topics_klingon.txt"
	stimList = Read Strings from raw text file: session_stimuli$
	nStimuli = 2
	# Explain the task.
	@EXPLAIN_TASK_3
	@SPACE_TO_CONTINUE: "PRACTICE: Task 3 - instructions"
	@PRESENT_STIMULI
endif
label SKIP_PRACTICE
practiceRound = 0


# Setup the recorder
demo Erase all
if selfService
	demo Text: 50, "centre", 70, "half", "You have finished the practice round. You are going to record your voice now."
	demo Text: 50, "centre", 60, "half", "If you can, use a quiet, echo-free room. Carpets, curtains, and bedding can all help."
	demo Text: 50, "centre", 50, "half", "You can use any high-quality recorder if you have one."
	demo Text: 50, "centre", 40, "half", "(In that case, please use 44.1 Hz sample rate and 24-bit WAV file.)"
	demo Text: 50, "centre", 30, "half", "Otherwise, follow the instructions on the next page to setup Praat's recorder."
else
	demo Text: 50, "centre", 60, "half", "You have finished the practice round."
	demo Text: 50, "centre", 50, "half", "You are going to record your voice now."
	demo Text: 50, "centre", 40, "half", "First, let the assistant setup the recorder."
endif
@SPACE_TO_CONTINUE: "Recorder setup."
# Instructions on how to record sound in Praat.
if selfService
	demo Erase all
	demo Text: 50, "centre", 80, "half", "Start the Recorder by pressing ""Ctrl+R"" in this window or"
	demo Text: 50, "centre", 70, "half", "by clicking on ""New"" \-> ""Record mono Sound..."" in the ""Praat Objects"" window."
	demo Text: 50, "centre", 60, "half", "Then press SPACE to continue."
	demo Insert picture from file: stimuli$ + slash$ + "01_start_recorder.png", 50, 50, 30, 50
	@SPACE_TO_CONTINUE: "Starting the recorder"
endif
# Testing the recorder.
if selfService
	demo Erase all
	demo Insert picture from file: stimuli$ + slash$ + "02_recorder_test.png", 18, 18, 17, 90
	demo Font size: 20
	demo Text: 37, "left", 85, "half", "Under ##Sampling frequency# Select ""44100 Hz"""
	demo Text: 37, "left", 75, "half", "Click on ""Record"" and say a few words."
	demo Text: 37, "left", 65, "half", "Then click on ""Stop"" and ""Play""."
	demo Text: 37, "left", 55, "half", "If you cannot hear your voice at all or not clearly enough,"
	demo Text: 37, "left", 45, "half", "try adjusting the microphone and the sound settings of the operating system."
	demo Text: 37, "left", 35, "half", "If all works fine, click on ""Record"" again and continue with this script."
	demo Font size: 24
	@SPACE_TO_CONTINUE: "Testing recorder"
endif


if beep
	# Ask the assistant to start the recorder.
	demo Erase all
	demo Text: 50, "centre", 60, "half", "You'll hear a beep sound at the beginning and end of recording."
	demo Text: 50, "centre", 50, "half", "The beeps are important for further processing of the recordings,"
	demo Text: 50, "centre", 40, "half", "so, please make sure that your speakers are on."
	demoShow ( )
	@SPACE_TO_CONTINUE: "Recorder check"
	selectObject: beep
	Play
endif
@CREATE_GRID: 2

################################################################################
# LANGUAGE BLOCKS
# Select the languages from the "language Table" one by one
################################################################################
if nUsedLangs > 4
	nUsedLangs = 4
endif
for l to nUsedLangs
	selectObject: langTab
	lang$ = Get value: l, "language"
	text_present$ = Get value: l, "text_present"

	# Explain the task.
	demo Erase all
	demo Text: 50, "centre", 70, "half", "Part 'l'"
	demo Text: 50, "centre", 60, "half", "Do the three tasks in the following language:"
	demo Font size: 50
	demo Text: 50, "centre", 45, "half", lang$
	demo Font size: 24
	@SPACE_TO_CONTINUE: "Part 'l' - 'lang$'"

	############################################################################
	# TASK I: Reading
	############################################################################
	task = 1
	# Set the maximum time for which the user can see an item.
	maxSeconds = 15

	if text_present$ = "yes"

		# Explain the task.
		@EXPLAIN_TASK_1_1
		@SPACE_TO_CONTINUE: "Task 1, instructions 1, 'lang$'"

		# Create the stimuli list
		stimList = Read Strings from raw text file: stimuli$ + slash$ + "aesop/" + lang$ + ".txt"
		nStimuli = Get number of strings

		# Show the whole text.
		demo Erase all
		for t to nStimuli
			selectObject: stimList
			text$ = Get string: t
			y_axis = 100 - (t * 8)
			demo Text: 50, "centre", y_axis, "half", text$
		endfor
		@SPACE_TO_CONTINUE: "Task 1, full text, 'lang$'"

		# Explain the task.
		@EXPLAIN_TASK_1_2
		@SPACE_TO_CONTINUE: "Task 1, instructions 2, 'lang$'"

		@PRESENT_TEXT

	else
		# Instruct to continue with next task if the text is not available.
		demo Erase all
		demo Text: 50, "centre", 60, "half", "Task 1: Reading"
		demo Text: 50, "centre", 50, "half", "No text is available for the 'lang$' language"
		demo Text: 50, "centre", 40, "half", "Continue with the next task"
		@SPACE_TO_CONTINUE: "Task 1 (no text available)"
	endif
	label SKIP_TASK_1


	################################################################################
	# TASK II: Semi-spontaneous tasks
	################################################################################
	# Each task has different "if's" in the PRESENT_STIMULI procedure.
	task = 2
	# Set the maximum time for which the user can see an item.
	maxSeconds = 60
	# Allow the user to go to the next item after 'allowNextAfter' seconds.
	allowNextAfter = 30;				# allow after this many seconds
	if debug > 0
		maxSeconds = 15
		allowNextAfter = 5
	endif
	# Don't allow users to skip items.
	skipBefore = -1
	# The user is allowed to show only a certain number of new topics.
	allowNext = maxSeconds

	# Load the picture list.
	session_stimuli$ = "pictures"
	stimList = Read Strings from raw text file: speakerPath$ + slash$ + session_stimuli$ + "_" + string$(session) + ".txt"
	nStrings = Get number of strings
	nStimuli = nStrings
	if nStrings > 5
		nStimuli = 5
	else
		nStimuli = nStrings
	endif
	if debug = 5
		nStimuli = 20
		allowNextAfter = -1
	endif

	# Explain the task.
	@EXPLAIN_TASK_2
	@SPACE_TO_CONTINUE: "Task 2, pictures, 'lang$'"

	@PRESENT_STIMULI

	################################################################################
	# TASK III: Spontaneous tasks - talk about topics
	################################################################################
	# Each task has different "if's" in the PRESENT_STIMULI procedure.
	task = 3
	# Set the maximum time for which the user can see an item.
	maxSeconds = 60
	# Allow the user to go to the next item after 'allowNextAfter' seconds.
	allowNextAfter = 30;				# = 0, allow this immediately
	# Allow users to skip items.
	skipBefore = 10
	# The user is allowed to skip only a certain number of stimuli.
	if nUsedLangs = 4
		allowNext = 12
	else
		allowNext = 15
	endif

	if debug > 0
		maxSeconds = 15
		allowNextAfter = -1
		skipBefore = 5
		allowNext = 199
	endif

	# Load the list of topics.
	session_stimuli$ = "topics"
	stimList = Read Table from tab-separated file: speakerPath$ + slash$ + session_stimuli$ + ".csv"
	nStimuli = 5

	# Explain the task.
	@EXPLAIN_TASK_3
	@SPACE_TO_CONTINUE: "Task 3, topics, 'lang$'"

	@PRESENT_STIMULI

	@UPDATE_GRID: "End of Part 'l' - 'lang$'"

	selectObject: grid
	Save as text file: grid$
endfor
removeObject: langTab

# Keep the grid so that it can be checked easily.
;;;removeObject: grid

label QUIT_SCRIPT


if beep
	selectObject: beep
	Play
endif
@UPDATE_GRID: "finished"


if selfService
	gridToRemove$ = sessionPath$ + "_instructions.TextGrid"
	if windows
		runSystem_nocheck: "del ", gridToRemove$
	elsif unix
		runSystem_nocheck: "rm ", gridToRemove$
	endif
endif

# End of the recording session.
demo Erase all
if selfService
	demo Text: 50, "centre", 60, "half", "You have finished the recording session."
	demo Text: 50, "centre", 50, "half", "Please, follow the instructions on how to stop the recorder,"
	demo Text: 50, "centre", 40, "half", "save the sound file and upload the data."
	@SPACE_TO_CONTINUE: "Finished the session."
else
	demo Text: 50, "centre", 70, "half", "You have finished recording session number 'session'"
	demo Text: 50, "centre", 60, "half", "Please, ask the assistant to stop the recorder now."
	if session < 3
		demo Text: 50, "centre", 50, "half", "Please, arrange the next recording session."
		demo Text: 50, "centre", 30, "half", "Thank you for your cooperation!"
	else
		demo Text: 50, "centre", 40, "half", "Thank you for taking part in the study!"
	endif
endif

# Instructions on how to stop the recorder.
if selfService
	demo Erase all
	demo Font size: 15
	# Stop recorder.
	demo Insert picture from file: stimuli$ + slash$ + "03_stop_recorder.png", 18, 18, 10, 73
	demo Text: 5, "left", 85, "half", "In the ##SoundRecorder# click on ""Stop"""
	demo Text: 5, "left", 80, "half", "and then on ""Save to list & Close""."
	# Save in correct format.
	demo Insert picture from file: stimuli$ + slash$ + "04_save_recording.png", 47, 47, 12, 73
	demo Text: 35, "left", 85, "half", "In the ##Objects# list select ""Sound untitled"""
	demo Text: 35, "left", 80, "half", "and ""Save as ##24-bit WAV# file""."
	# Save in correct place and correct name.
	demo Insert picture from file: stimuli$ + slash$ + "05_select_file_name.png", 79, 79, 20, 63
	demo Text: 65, "left", 85, "half", "Save the file in the automatically created folder:"
	demo Text: 65, "left", 80, "half", """01\_ recording/speakers/YOUR\_ NICKNAME/recordings"
	demo Text: 65, "left", 75, "half", "Copy the file name from the TextGrid file,"
	demo Text: 65, "left", 70, "half", "and replace ##"".TextGrid""# with the ##"".wav""# extension."
	demo Font size: 24
	@SPACE_TO_CONTINUE: "Stopping the recorder."
endif

# Instructions on how to compress the data and upload.
if selfService
	demo Erase all
	demo Font size: 15
	# Zip the data.
	demo Insert picture from file: stimuli$ + slash$ + "06_compress.png", 24, 24, 15, 71
	demo Text: 5, "left", 85, "half", "Compress the folder with your data,"
	demo Text: 5, "left", 80, "half", "e.g., in Windows 10, you can do it like this:"
	demo Text: 5, "left", 75, "half", "Right-Click the folder and select ""Send to"" \-> ""Compressed"""
	# Upload to cloud.upol.cz
	demo Insert picture from file: stimuli$ + slash$ + "07_upload.png", 72, 72, 7, 70
	demo Text: 50, "left", 90, "half", "Finally, upload the zip to my University storage"
	demo Text: 50, "left", 85, "half", "by going to the following address in your browser:"
	demo Text: 50, "left", 80, "half", "https://cloud.ff.upol.cz/index.php/s/TGWN4r53Drsk8Jk"
	demo Text: 50, "left", 75, "half", "(On some computers it's possible to click the link.)"
	demo Font size: 24
	@DRAW_CONTINUE_BUTTON
	while demoWaitForInput ( )
		# enable quitting the script immediately.
		if demoClickedIn (50, 80, 80, 85)
			browser$ = ""
			if windows
				if fileReadable ("C:\Program Files\Mozilla Firefox\firefox.exe")
					browser$ = "C:\Program Files\Mozilla Firefox\firefox.exe"
				elsif fileReadable ("C:\Program Files (x86)\Mozilla Firefox\firefox.exe")
					browser$ = "C:\Program Files (x86)\Mozilla Firefox\firefox.exe"
				elsif fileReadable ("C:\Program Files (x86)\Google\Chrome\Application\chrome.exe")
					browser$ = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
				elsif fileReadable ("C:\Program Files\Google\Chrome\Application\chrome.exe")
					browser$ = "C:\Program Files\Google\Chrome\Application\chrome.exe"
				endif
			elsif unix
				browser$ = "firefox"
			endif
			if browser$ <> ""
				runSystem_nocheck: """'browser$'"" https://cloud.ff.upol.cz/index.php/s/TGWN4r53Drsk8Jk"
			else
				writeInfoLine: "Praat does not allow copying text from the picture window, but you can copy the address from here:"
				appendInfoLine: "https://cloud.ff.upol.cz/index.php/s/TGWN4r53Drsk8Jk"
			endif
		endif
		if demoKey$ ( ) = " " or demoClickedIn (38, 62, 2, 8)
			goto CONT
		endif
	endwhile
	label CONT
	@UPDATE_GRID: updateGrid$
endif

# label QUIT_SCRIPT
label FULL_QUIT

if selfService
	demo Erase all
	demo Text: 50, "centre", 60, "half", "Thank you for taking part in the study!"
	demo Text: 50, "centre", 50, "half", "You can close all Praat windows now."
endif

demoShow ( )

# Keep this as the last line in the script (before procedures) so that the
# script can be interrupted properly.
label CANCEL
if beep
	removeObject: beep
endif

exit

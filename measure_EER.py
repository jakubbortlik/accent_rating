import numpy as np
import os
import sys

from matplotlib import pyplot  # doctest: +SKIP

from sklearn import metrics


def pattern_in_both(pattern, line):
    """Return True if pattern matches in both filenames else False"""
    file1, file2, *_ = line.split('\t')
    if pattern in file1 and pattern in file2:
        return True
    else:
        return False


def pattern_in_neither(pattern, line):
    """Return True if pattern matches in neither of the filenames else False"""
    file1, file2, *_ = line.split('\t')
    if pattern not in file1 and pattern not in file2:
        return True
    else:
        return False


def pattern_in_one(pattern, line):
    """Return True if pattern matches in exactly one of the filenames else False"""

    file1, file2, *_ = line.split('\t')
    if (pattern in file1 and pattern not in file2) or (pattern not in file1 and pattern in file2):
        return True
    else:
        return False


def filter_lines(in_file, conditions) -> list:
    """Filter the results table according to conditions specified

    Args:
        in_file: TextIOWrapper containing the results table
        conditions: None, or a tuple specifying the pattern that has
            appear in the filenames of "neither", "both", or "one" of
            the recordings
    """

    if conditions is None:
        return [line for line in in_file]
    elif len(conditions) == 2:
        operator, pattern = conditions
    else:
        sys.exit(f'Bad number of conditions (expected 2): {conditions}')

    if operator == 'both':
        return [line for line in in_file if pattern_in_both(pattern, line)]
    elif operator == 'neither':
        return [line for line in in_file if pattern_in_neither(pattern, line)]
    elif operator == 'one':
        return [line for line in in_file if pattern_in_one(pattern, line)]
    else:
        sys.exit(f'Bad operator (must be one of ["both", "neither", "one"]): {operator}')


def get_labels(subset: list) -> list:
    """Return same- and different-speaker labels for recording pairs

    Args:
        subset: list of lines from the results table

    Returns:
        List of same (1) and different (0) speaker labels for the
            recording pairs in the subset.
    """

    labels = list()
    for line in subset:
        _, _, spk1, spk2, *_ = line.split('\t')
        label = '1' if spk1 == spk2 else '0'
        labels.append(label)
    return labels


def plot_together(
    conditions_dict: dict, scores_column: int, eer_dir: str, title='',
    main_filter=''
):
    """Plot the data sets defined in conditions_dict in one graph

    Args:
        conditions_dict: dictionary of condition names and filters for
            selecting a subset of the recordings/embeddings
        scores_column: the number of the column in the results table
            that contains the scores for the given technology (sid4 or
            spkrec)
        eer_dir: directory for saving temporary files
        title: main plot title
        main_filter: main filter for restricting the subset ("phone" or
            "original")
    """

    fig, ax_roc = pyplot.subplots(1, 1)
    fig.set_figwidth(6.4)
    fig.set_figheight(6.4)

    for model, conditions in conditions_dict.items():
        with open('sid_results_table_individual_files_filtered.csv') as in_file:
            _ = in_file.readline()
            subset = filter_lines(in_file, conditions)
            if main_filter in {'original', 'phone'}:
                subset = [line for line in subset if (line.split('\t')[8] == main_filter and line.split('\t')[9] == main_filter)]
            labels = get_labels(subset)
            predictions = [line.split('\t')[scores_column] for line in subset]
            names = ['\t'.join([line.split('\t')[0], line.split('\t')[1]]) for line in subset]

            with open(f'{eer_dir}/names_{model.replace(" ", "_")}.txt', 'w') as out_file:
                out_file.writelines(name + '\n' for name in names)
            with open(f'{eer_dir}/labels_{model.replace(" ", "_")}.txt', 'w') as out_file:
                out_file.writelines(label + '\n' for label in labels)
            with open(f'{eer_dir}/predictions_{model.replace(" ", "_")}.txt', 'w') as out_file:
                out_file.writelines(pred + '\n' for pred in predictions)

        y = np.array([int(x) for x in labels])
        y_pred = np.array([float(x) for x in predictions])

        # Calculate EER adn EER threshold
        fpr, fnr, threshold = metrics.det_curve(y, y_pred, pos_label=1)
        fpr, fnr = fpr * 100, fnr * 100
        eer_threshold = round(threshold[np.nanargmin(np.absolute((fnr - fpr)))], ndigits=2)
        eer = round(fpr[np.nanargmin(np.absolute((fnr - fpr)))], ndigits=1)

        # DET curve
        fpr, fnr = fpr / 100, fnr / 100
        display = metrics.DetCurveDisplay(
            fpr=fpr, fnr=fnr, estimator_name=f'{model} (n = {len(names)}), EER = {eer} %, threshold = {eer_threshold}'
        )
        display.plot(ax_roc)

    # pyplot.title(title)
    pyplot.tight_layout()
    pyplot.legend(loc=0)
    pyplot.show()      # doctest: +SKIP


if __name__ == '__main__':
    eer_dir = 'EER_measurements'
    os.makedirs(eer_dir, exist_ok=True)
    phonexia_langs = {
        'sid4 - all': None,
        'sid4 - cz-cz': ('both', 'Cz'),
        'sid4 - cz-en': ('one', 'En'),
        'sid4 - en-en': ('both', 'En'),
    }
    phonexia_channel = {
        'sid4 - all': None,
        'sid4 - phone-phone': ('both', 'phone'),
        'sid4 - orig-phone': ('one', 'phone'),
        'sid4 - orig-orig': ('neither', 'phone'),
    }
    speechbrain_langs = {
        'spkrec - all': None,
        'spkrec - cz-cz': ('both', 'Cz'),
        'spkrec - cz-en': ('one', 'En'),
        'spkrec - en-en': ('both', 'En'),
    }
    speechbrain_channel = {
        'spkrec - all': None,
        'spkrec - phone-phone': ('both', 'phone'),
        'spkrec - orig-phone': ('one', 'phone'),
        'spkrec - orig-orig': ('neither', 'phone'),
    }

    plot_together(phonexia_langs, 10, eer_dir, title='Phonexia SID4-XL4 - language (mis)match', main_filter='phone')
    plot_together(speechbrain_langs, 11, eer_dir, title='SpeechBrain spkrec-ecapa-voxceleb - language (mis)match', main_filter='phone')
    plot_together(phonexia_langs, 10, eer_dir, title='Phonexia SID4-XL4 - language (mis)match', main_filter='original')
    plot_together(speechbrain_langs, 11, eer_dir, title='SpeechBrain spkrec-ecapa-voxceleb - language (mis)match', main_filter='original')

    plot_together(phonexia_channel, 10, eer_dir, title='Phonexia SID4-XL4 - channel (mis)match', main_filter=None)
    plot_together(speechbrain_channel, 11, eer_dir, title='SpeechBrain spkrec-ecapa-voxceleb - channel (mis)match', main_filter=None)
    plot_together(phonexia_channel, 10, eer_dir, title='Phonexia SID4-XL4 - channel (mis)match', main_filter=None)
    plot_together(speechbrain_channel, 11, eer_dir, title='SpeechBrain spkrec-ecapa-voxceleb - channel (mis)match', main_filter=None)

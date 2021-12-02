import os

import torch

from sklearn.utils.extmath import softmax
from speechbrain.pretrained import EncoderClassifier


class EncoderClassifierAllLangs(EncoderClassifier):
    def save_emb(self, emb, path, emb_ext):
        wav_dir, basename = os.path.split(path)
        emb_dir = wav_dir.replace('samples_16kHz', 'embeddings_lid')
        emb_path = self.get_emb_path(emb_dir, basename, emb_ext)
        torch.save(emb, emb_path)

    def get_emb_path(self, emb_dir, basename, emb_ext):
        root, ext = os.path.splitext(basename)
        emb_path = os.path.join(emb_dir, root + emb_ext)
        return emb_path

    def classify_file(self, path, emb_ext, use_softmax=True):
        """Classifies the given audiofile into the given set of labels.

        Arguments
        ---------
        path : str
            Path to audio file to classify.

        Returns
        -------
        czech_score
            The log posterior probability of class Czech
        english_score
            The log posterior probability of class English
        best_score:
            It is the value of the log-posterior for the best class ([batch,])
        text_lab:
            List with the text labels corresponding to the indexes.
            (label encoder should be provided).
        """
        waveform = self.load_audio(path)
        # Fake a batch:
        batch = waveform.unsqueeze(0)
        rel_length = torch.tensor([1.0])
        emb = self.encode_batch(batch, rel_length)

        self.save_emb(emb, path, emb_ext)

        out_prob = self.modules.classifier(emb).squeeze(1)
        if use_softmax:
            out_prob = torch.tensor(softmax(out_prob))

        # Get the scores for Czech and Enlish and the best matching language:
        czech_score = round(out_prob[0][23].item(), ndigits=4)
        english_score = round(out_prob[0][24].item(), ndigits=4)
        best_score, index = torch.max(out_prob, dim=-1)
        best_score = round(best_score.item(), ndigits=4)
        text_lab = self.hparams.label_encoder.decode_torch(index)
        return czech_score, english_score, best_score, text_lab

    def classify_emb(self, path, use_softmax=True):
        """Classifies the given audiofile into the given set of labels.

        Arguments
        ---------
        path : str
            Path to embedding file to classify.

        Returns
        -------
        czech_score
            The log posterior probability of class Czech
        english_score
            The log posterior probability of class English
        best_score:
            It is the value of the log-posterior for the best class ([batch,])
        text_lab:
            List with the text labels corresponding to the indexes.
            (label encoder should be provided).
        """
        emb = torch.load(path)
        out_prob = self.modules.classifier(emb).squeeze(1)
        if use_softmax:
            out_prob = torch.tensor(softmax(out_prob))
            for x in out_prob[0]:
                print(x.item())
        czech_score = round(out_prob[0][23].item(), ndigits=4)
        english_score = round(out_prob[0][24].item(), ndigits=4)
        best_score, index = torch.max(out_prob, dim=-1)
        best_score = round(best_score.item(), ndigits=4)
        text_lab = self.hparams.label_encoder.decode_torch(index)
        return czech_score, english_score, best_score, text_lab


classifier = EncoderClassifierAllLangs.from_hparams(source="speechbrain/lang-id-commonlanguage_ecapa", savedir="pretrained_models/lang-id-commonlanguage_ecapa")


def get_emb_path(emb_dir, basename, emb_ext):
    """Return the joined embedding path"""
    root, ext = os.path.splitext(basename)
    emb_path = os.path.join(emb_dir, root + emb_ext)
    return emb_path


def path(data_dir, file_name):
    """Return the joined full path of file_name"""
    return os.path.join(data_dir, file_name)


def ext(file_name: str) -> str:
    """Return the extension of the file specified by file_name"""
    return os.path.splitext(file_name)[1]


def get_file_list(data_dir: str, extension: str) -> list:
    """Return a list of file paths in data_dir that match the given extension

    Args:
        data_dir: path of the data directory
        extension: extension for filtering the list of files

    Returns: list of files
    """

    all_files = os.listdir(data_dir)
    file_list = (path(data_dir, f) for f in all_files if ext(f) == extension)
    return file_list


def generate_scores_from_wavs(wav_list, emb_ext, use_softmax=True):
    """Generate the score file from a list of audio files

    Args:
        wav_list: list of absolute paths to audio files
        emb_ext: extension of the file for saving the embedding
        use_softmax: True if probabilities are to be transformed by softmax

    Yields:
        Lines with scores for Czech, English, the score for the best-matching
            language and its name.
    """

    for wav in wav_list:
        czech_score, english_score, best_score, text_lab = classifier.classify_file(wav, emb_ext, use_softmax=use_softmax)
        basename = os.path.split(wav)[1]
        line = '\t'.join([basename, str(czech_score), str(english_score), str(best_score), text_lab[0]])
        yield line + '\n'


def generate_scores_from_embs(emb_list, use_softmax=True):
    """Generate the scrore file from a list of embeddings

    Args:
        emb_list: list of absolute paths to embeddings
        use_softmax: True if probabilities are to be transformed by softmax

    Yields:
        Lines with scores for Czech, English, the score for the best-matching
    """

    for emb in emb_list:
        czech_score, english_score, best_score, text_lab = classifier.classify_emb(emb, use_softmax=use_softmax)
        basename = os.path.split(emb)[1]
        line = '\t'.join([basename, str(czech_score), str(english_score), str(best_score), text_lab[0]])
        yield line + '\n'


if __name__ == '__main__':
    # The script can either compute embeddings from audio files or load them
    # from files saved in a prvious run:
    LOAD_EMBEDDINGS = 0
    # I considered transforming the probabilities with softmax, but then
    # decided to use the original output of the EncoderClassifier:
    USE_SOFTMAX = False

    emb_dir = '~/embeddings_lid'
    emb_ext = '.lid'
    wav_dir = '~/samples_16kHz'
    wav_ext = '.wav'
    os.makedirs(emb_dir, exist_ok=True)

    if LOAD_EMBEDDINGS == 1:  # Load embeddings
        emb_list = get_file_list(emb_dir, emb_ext)
        score_gen = generate_scores_from_embs(emb_list, use_softmax=USE_SOFTMAX)
        score_file = os.path.join(emb_dir, 'speechbrain_lid_from_emb.sco')
    else:  # Compute embeddings
        wav_list = get_file_list(wav_dir, wav_ext)
        score_gen = generate_scores_from_wavs(wav_list, emb_ext, use_softmax=USE_SOFTMAX)
        score_file = os.path.join(emb_dir, 'speechbrain_lid_from_wav.sco')

    with open(score_file, 'w') as out_file:
        out_file.writelines(score_gen)
        print('Writing scores to file', score_file)

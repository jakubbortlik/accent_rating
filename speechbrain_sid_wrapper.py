import os

from itertools import combinations

import torch
import torchaudio

from speechbrain.pretrained import SpeakerRecognition
from speechbrain.pretrained import EncoderClassifier


class SpeakerRecognitionWithEmbeddings(SpeakerRecognition):
    def verify_batch(self, emb1, emb2, threshold=0.25):
        """Performs speaker verification with cosine distance.

        It returns the score and the decision (0 different speakers,
        1 same speakers).

        Arguments
        ---------
        emb1 : Torch.Tensor
                Tensor containing precomputed embeddings1
        emb2 : Torch.Tensor
                Tensor containing precomputed embeddings2.
        threshold: Float
                Threshold applied to the cosine distance to decide if the
                speaker is different (0) or the same (1).

        Returns
        -------
        score
            The score associated to the binary verification output
            (cosine distance).
        prediction
            The prediction is 1 if the two signals in input are from the same
            speaker and 0 otherwise.
        """
        score = self.similarity(emb1, emb2)
        return score, score > threshold


classifier = EncoderClassifier.from_hparams(source="speechbrain/spkrec-ecapa-voxceleb")
verification = SpeakerRecognitionWithEmbeddings.from_hparams(source="speechbrain/spkrec-ecapa-voxceleb", savedir="pretrained_models/spkrec-ecapa-voxceleb")


def get_emb_path(emb_dir, basename, emb_ext):
    root, ext = os.path.splitext(basename)
    emb_path = os.path.join(emb_dir, root + emb_ext)
    return emb_path


def make_embeddings(file_name, emb_dir, emb_ext):
    basename = os.path.split(file_name)[-1]
    print('[INFO] Processing file:', basename)
    emb_path = get_emb_path(emb_dir, basename, emb_ext)

    signal, fs = torchaudio.load(file_name)
    embeddings = classifier.encode_batch(signal, normalize=True)
    torch.save(embeddings, emb_path)

    return embeddings


def path(data_dir, file_name):
    return os.path.join(data_dir, file_name)


def ext(file_name):
    return os.path.splitext(file_name)[1]


def get_file_list(data_dir):
    all_files = os.listdir(data_dir)
    file_list = (path(data_dir, f) for f in all_files if ext(f) == '.wav')
    return file_list


def get_scores(emb_dict):
    combos = combinations(emb_dict, 2)
    for i, j in combos:
        basename1, basename2 = os.path.split(i)[-1], os.path.split(j)[-1]
        emb1, emb2 = emb_dict[i], emb_dict[j]
        score, prediction = verification.verify_batch(emb1, emb2)
        score = str(round(score.item(), ndigits=6))
        prediction = str(prediction.item())
        line = '\t'.join([basename1, basename2, score, prediction])
        print(line)
        yield line + '\n'


def get_scores_permutations(emb_dict: dict):
    for i in emb_dict:
        for j in emb_dict:
            basename1 = os.path.splitext(os.path.split(i)[-1])[0]
            basename2 = os.path.splitext(os.path.split(j)[-1])[0]
            emb1, emb2 = emb_dict[i], emb_dict[j]
            score, prediction = verification.verify_batch(emb1, emb2)
            score = str(round(score.item(), ndigits=6))
            prediction = str(prediction.item())
            line = '\t'.join([basename1, basename2, score, prediction])
            print(line)
            yield line + '\n'


if __name__ == '__main__':
    wav_dir = './05_SID_experiments/samples_16kHz'
    emb_dir = './05_SID_experiments/embeddings'
    emb_ext = '.sid'
    os.makedirs(emb_dir, exist_ok=True)
    wav_list = get_file_list(wav_dir)

    load_embeddings = False
    if load_embeddings:  # Load embeddings
        emb_list = (os.path.join(emb_dir, f) for f in os.listdir(emb_dir) if os.path.splitext(f)[1] == emb_ext)
        emb_dict = {f: torch.load(f) for f in emb_list}
    else:                # Compute embeddings
        emb_dict = {w: make_embeddings(w, emb_dir, emb_ext) for w in wav_list}

    get_combinations = False
    if get_combinations:
        score_file = os.path.join(emb_dir, 'scores_combinations.sco')
        with open(score_file, 'w') as out_file:
            scores = get_scores(emb_dict)
            out_file.writelines(scores)
    else:
        score_file = os.path.join(emb_dir, 'scores_permutations.sco')
        with open(score_file, 'w') as out_file:
            scores = get_scores_permutations(emb_dict)
            out_file.writelines(scores)

    print('scores saved as', score_file)

#!/usr/bin/env python3

import argparse
import numpy as np
import pandas as pd
import hdbscan


def read_mash_triangle(filename):
    """
    Read mash triangle output.

    Returns
    -------
    names : list
        Sequence names
    D : ndarray
        NxN symmetric distance matrix
    """

    with open(filename) as fh:
        n = int(next(fh).strip())

        names = []
        D = np.zeros((n, n), dtype=float)

        for i, line in enumerate(fh):
            fields = line.rstrip().split("\t")

            names.append(fields[0])

            distances = [float(x) for x in fields[1:]]

            for j, d in enumerate(distances):
                D[i, j] = d
                D[j, i] = d

    return names, D


def main():

    parser = argparse.ArgumentParser()
    parser.add_argument("triangle")
    parser.add_argument("output")
    parser.add_argument(
        "--min-cluster-size",
        type=int,
        default=5,
    )
    parser.add_argument(
        "--min-samples",
        type=int,
        default=None,
    )

    args = parser.parse_args()

    names, D = read_mash_triangle(args.triangle)

    clusterer = hdbscan.HDBSCAN(
        metric="precomputed",
        min_cluster_size=args.min_cluster_size,
        min_samples=args.min_samples,
    )

    labels = clusterer.fit_predict(D)

    out = pd.DataFrame(
        {
            "sequence": names,
            "cluster": labels,
            "probability": clusterer.probabilities_,
        }
    )

    out.to_csv(args.output, sep="\t", index=False)


if __name__ == "__main__":
    main()
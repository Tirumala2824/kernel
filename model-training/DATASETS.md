# Proxy dataset survey (2026-10-10)

**Goal:** a public, clearly licensed acoustic or vibration dataset with
**clean vs infested** labels. Recordings of larvae feeding or boring inside a
substrate are preferred. It trains an *experimental proxy* model while no
grain-sack recordings exist.

**Searched:**
- Zenodo records API (`/api/records?q=...`, with and without `type=dataset` and `title:(...)` queries)
- Dryad API v2 search
- figshare API search, which also covers USDA Ag Data Commons
- the Kaggle public dataset API
- DataCite

The helper scripts are in `tools/` (`zenodo_search.py`, `zenodo_record.py`, `repo_search.py`,
`figshare_record.py`, `kaggle_files.py`, `xlsx_dump.py`).

**Licence rule:** only CC0, CC BY, U.S. Public Domain or equivalent are used. Non-commercial, unknown or
unclear licences are excluded outright.

## Chosen: TreeVibes, with TV-PAVC v1 provenance folds

| | |
|---|---|
| URL | https://www.kaggle.com/datasets/potamitis/treevibes (Kaggle ref `potamitis/treevibes`) |
| Licence | **CC0 1.0 (public domain)**, per the Kaggle dataset metadata `licenseName: "CC0: Public Domain"` |
| Paper | Rigakis I., Potamitis I., Tatlas N.-A., Potirakis S. M., Ntalampiras S. (2021). *TreeVibes: Modern Tools for Global Monitoring of Trees for Borers.* Smart Cities 4(1), 271-285. doi:10.3390/smartcities4010017 |
| Size | 10.15 GB in total, 59,602 files: 4,154 field WAVs, about 54.6k lab WAVs, plus OGG/PKF. **We downloaded about 1.5 GB: all 4,093 retained field clips plus 737 lab clips (unused)** |
| Sample rate | **8 kHz**, mono, PCM16 WAV. Field clips are about 20 s, lab clips 10 s |
| Sensor | Field: a piezoelectric contact transducer coupled through a drill bit or metal waveguide inserted in the trunk. Lab: logs recorded with a Roland R4 |
| Labels | Clean vs infested **per folder (tree / placement)**. `TreeVibes.xlsx` has AUDIO (1 = infested), VISUAL and CONFIRMATION columns, and the folder path is train/clean or train/infested. Species include *Rhynchophorus ferrugineus* (red palm weevil), *Xylotrechus chinensis* and other wood borers |
| Relevance to grain sacks | **The closest structural analogue found.** The audio is insect larvae feeding and moving *inside a solid substrate*, labelled clean vs infested at the source level, and the impulsive feeding pulses resemble the grain-weevil larval sounds in the stored-product literature. Main gaps: (1) wood vs grain, (2) a contact piezo sensor vs a phone microphone pressed on a sack, and (3) 8 kHz bandwidth, so the model only sees content below about 3.8 kHz. |

| | |
|---|---|
| Split metadata | **TV-PAVC v1**, Ayoub A. (2026), Zenodo, doi:10.5281/zenodo.21993431 |
| Licence | CC BY 4.0 (documentation, manifests, folds), MIT (code). No audio is redistributed |
| What we use | Its decoded-PCM de-duplication (2,107 → 2,072 primary clips), its 23 provenance groups (folders 3 and 4 linked) and its 6 fixed grouped folds, so that **no tree or source is on both sides of a split**. Also its usage atlas: lab clips have unrecoverable parent-recording lineage, so they are used **for training only** |

**How we split.** Every split is by provenance group, never by clip or window. The code is in `kernel_train/treevibes.py`.

| Split | Groups | Clips (clean / infested) |
|---|---|---|
| train | primary folds 1-3: clean folders 7, 10, 24; infested 2, 5, 11, 16, 17, 19, 20, 21, 23 | 628 / 437 field clips (6.0 h) |
| val | primary fold 4: clean folder 8; infested 6, 13, 14 | 238 / 109 (2.0 h) |
| test | primary folds 5-6: clean folders 9, 25; infested 1, 3/4, 12, 18, 22 | 535 / 125 (3.7 h) |
| challenge (hard negatives) | folder 35 (AUDIO = 0 clips recorded on infested trees) | 332 / 0 |
| challenge (positive only) | folder 15 and the official test folders 26-34. Sensitivity only, no specificity | 0 / 1,689 |

**Integrity:**
- Each field file was checked against TV-PAVC's raw-file SHA-256 on download.
- Our decoded-PCM hashes matched TV-PAVC's `sha256_pcm` for all 4,093 field clips (0 mismatches).
- No PCM duplicate crosses splits.

**Lab clips.** `selection.csv` lists 967 lab clean clips plus a fixed-seed 1,500 of the lab infested clips (development only). They are **not used in kernel-proxy-0.1**, for three reasons:
- Kaggle rate-limited the download (HTTP 429) after 737 lab clean clips and no lab infested ones.
- Training on lab clean without lab infested would teach a recorder shortcut ("lab means clean").
- TV-PAVC says their lineage is unresolved anyway.

`python -m kernel_train.prep --domains field` reproduces 0.1. A later run can add `lab` once it is fully downloaded.

## Candidates considered and not used

| Dataset | URL | Licence | Size | Sample rate | Labels | Relevance / why not used |
|---|---|---|---|---|---|---|
| USDA ARS *Bug Bytes* sound library (R. Mankin) | https://doi.org/10.15482/USDA.ADC/1504600 (Ag Data Commons 24664824) | U.S. Public Domain | 55 MB zip, ~95 WAV clips of 3-60 s | Varies by sensor (not verified; not downloaded) | Species/category descriptions per clip. Only ~3 pure background-noise clips (I.3, I.4, I.6) and no clean-grain controls | **The most grain-relevant audio found**: *Sitophilus oryzae* larvae in wheat, *S. zeamais* larvae/adults in maize, *Prostephanus truncatus*, *Plodia* larvae. But it is about 15 minutes in total, mixes many sensors, and has no clean class, so it cannot train or evaluate a 2-class model. A good candidate for qualitative listening checks |
| Phillips, Morrison, Gerken (2026). *Acoustic detection and classification of three stored product insect pests* | https://doi.org/10.15482/USDA.ADC/32663844.v1 | CC0 | 2 small files: a CSV of extracted vibration features and a key | n/a | *R. dominica*, *T. castaneum*, *S. zeamais* adults at 5/20/40 per kg wheat | Highly relevant (an accelerometer on grain) but **no audio** is released, so no log-mel CNN can be trained on it |
| Görres & Chesmore (2019). *Active sound production of scarab beetle larvae...* | https://doi.org/10.5061/dryad.2j87692 (mirror: https://zenodo.org/records/5059656) | CC0 | 10.13 GB (4 zips, 0.39-4.78 GB) | Not verified. Pre-processed, band-passed 200-5000 Hz | Species (*Melolontha melolontha*, *M. hippocastani*) and larva count. **Every recording contains larvae**; there are no empty-soil controls | Larvae in a substrate (soil), but with no clean class it cannot supply clean vs infested labels |
| Kaggle "Acoustic Dataset" (Red Palm Weevil) | https://www.kaggle.com/datasets/navyaephrin/dataset | **CC BY-NC-SA 4.0** | 0.81 GB | not checked | RPW presence | Excluded: the **non-commercial** licence does not clearly allow this use |
| Kaggle "Red palm weevil Dataset" | https://www.kaggle.com/datasets/drabdulmateenahmed/red-palm-weevil-dataset | **Unknown** | small | not checked | binary RPW presence | Excluded: **unclear licence** |
| InsectSound1000 (Branding et al., Sci Data 2024) | https://doi.org/10.5073/20231024-173119-0 (OpenAgrar) | CC BY 4.0 | Size not exposed by the API. Per the paper, ~166k 2.5 s 4-channel clips, so tens of GB | 16 kHz | 12 species of **flying** insects in a greenhouse box | Weak: wing-beat/flight sounds, no substrate, no clean vs infested. The sibling *InsectSound1000-GreenhouseNoiseRecordings* (doi:10.5073/20260415-170032-0, CC BY 4.0) could serve as background-noise augmentation later |
| *Acoustic Emission signal characteristics of the larvae of Coscinesthes salicis* | https://zenodo.org/records/6383418 | CC BY | 1 xlsx | n/a | n/a | No audio, only extracted AE parameters |
| Red palm weevil / *Sitophilus* / *Tribolium* / termite searches on Zenodo, Dryad and figshare | n/a | n/a | n/a | n/a | n/a | No audio dataset with a usable licence and clean controls. RPW larvae recordings are in TreeVibes |

## Implications recorded in the model card

- The model learns *"impulsive larval feeding/moving vibrations inside wood, picked up by a contact
  piezo, vs background"*. That is a **proxy task**. Nothing here measures detection of grain pests in
  sacks with a phone microphone.
- TreeVibes is 8 kHz, so the model is band-limited in-graph to the mel bands below about 3.8 kHz.
  The app's front end (16 kHz, 64 mels, 125-7500 Hz) is unchanged.
- The retrain path (`retrain.py`) replaces this proxy with a model trained on the team's own labelled grain
  recordings (`validation=field`).

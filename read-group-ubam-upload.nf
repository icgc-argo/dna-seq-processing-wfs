#!/bin/bash nextflow

/*
 * Copyright (c) 2019, Ontario Institute for Cancer Research (OICR).
 *                                                                                                               
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

/*
 * Author: Junjun Zhang <junjun.zhang@oicr.on.ca>
 */

nextflow.preview.dsl=2

params.seq_experiment = "tests/data/seq_exp-fq.song-analysis.json"
params.files_to_upload = "tests/data/C0HVY_2.lane.bam"
params.all_files = [
  "tests/data/C0HVY_2.lane.bam",
  "tests/data/D0RE2_1.lane.bam",
  "tests/data/D0RH0_2.lane.bam"
]
params.wf_short_name = "dna-seq-alignment"
params.wf_version = "0.2.3.0"
params.song_url = "https://song.qa.argo.cancercollaboratory.org"
params.score_url = "https://score.qa.argo.cancercollaboratory.org"
params.token_file = "/home/ubuntu/.access_token"
params.upload_ubam = false

include payloadGenReadGroupUbam from "./modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/payload-gen-read-group-ubam.0.1.0.0/tools/payload-gen-read-group-ubam/payload-gen-read-group-ubam.nf" params(params)
include SongPayloadUpload from "./modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/song-payload-upload.0.1.0.0/tools/song-payload-upload/song-payload-upload.nf" params(params)
include songAnalysisGet from "./modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/song-analysis-get.0.1.0.0/tools/song-analysis-get/song-analysis-get.nf" params(params)
include scoreManifestGen from "./modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/score-manifest-gen.0.1.0.0/tools/score-manifest-gen/score-manifest-gen.nf" params(params)
include scoreUpload from "./modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/score-upload.0.1.0.0/tools/score-upload/score-upload.nf" params(params)
include songAnalysisPublish from "./modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/song-analysis-publish.0.1.0.0/tools/song-analysis-publish/song-analysis-publish.nf" params(params)


workflow ReadGroupUbamUpload {
  get:
    seq_experiment
    files_to_upload
    all_files
    wf_short_name
    wf_version
    song_url
    score_url
    token_file
    upload_ubam

  main:
    payloadGenReadGroupUbam(seq_experiment, files_to_upload, wf_short_name, wf_version)

    SongPayloadUpload(song_url, payloadGenReadGroupUbam.out.payload, token_file)

    songAnalysisGet(SongPayloadUpload.out.analysis_id, SongPayloadUpload.out.study, song_url, token_file)

    if (upload_ubam) {
      scoreManifestGen(songAnalysisGet.out.song_analysis, all_files)

      scoreUpload(scoreManifestGen.out.manifest_file, all_files, token_file, song_url, score_url)

      songAnalysisPublish(SongPayloadUpload.out.analysis_id, SongPayloadUpload.out.study, scoreUpload.out[0], song_url, token_file)
    }

  emit:
    read_group_ubam_analysis = songAnalysisGet.out.song_analysis
}

workflow {
  ReadGroupUbamUpload(
    file(params.seq_experiment),
    file(params.files_to_upload),
    Channel.fromPath(params.all_files).collect(),
    params.wf_short_name,
    params.wf_version,
    params.song_url,
    params.score_url,
    params.token_file,
    params.upload_ubam
  )

  publish:
    ReadGroupUbamUpload.out.read_group_ubam_analysis to: "outdir", overwrite: true
}

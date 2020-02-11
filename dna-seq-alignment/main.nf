#!/usr/bin/env nextflow
nextflow.preview.dsl=2
name = 'dna-seq-alignment'


/*
========================================================================================
                        ICGC-ARGO DNA SEQ ALIGNMENT
========================================================================================
#### Homepage / Documentation
https://github.com/icgc-argo/dna-seq-processing-wfs
#### Authors
Alexandru Lepsa @lepsalex <alepsa@oicr.on.ca>
Linda Xiang @lindaxiang <linda.xiang@oicr.on.ca>
Junjun Zhang @junjun-zhang <junjun.zhang@oicr.on.ca>
----------------------------------------------------------------------------------------

Required Parameters (no default):
--study_id                              song study ID
--analysis_id                           song sequencing_experiment analysis ID
--ref_genome_gz                         reference genome '.fa.gz' file, other secondary files are expected to be under the same folder
--song_url                              song server URL
--score_url                             score server URL
--api_token                             song/score API Token

General Parameters (with defaults):
--cpus                                  cpus given to all process containers (default 1)
--mem                                   memory (GB) given to all process containers (default 1)

Download Parameters (object):
--download
{
    song_container_version              song docker container version, defaults set below
    score_container_version             score docker container version, defaults set below
    song_url                            song url for download process (defaults to main song_url param)
    score_url                           score url for download process (defaults to main score_url param)
    api_token                           song/score API token for download process (defaults to main api_token param)
    song_cpus
    song_mem
    score_cpus
    score_mem
    score_transport_mem                 TODO: Description
}

seqDataToLaneBam Parameters (object):
--seqDataToLaneBam
{
    container_version                   docker container version, defaults to unset
    reads_max_discard_fraction          seqDataToLaneBam reads max discard fraction
    cpus                                cpus for seqDataToLaneBam container, defaults to cpus parameter
    mem                                 memory (GB) for seqDataToLaneBam container, defaults to mem parameter
    tool                                splitting tool, choices=['picard', 'samtools'], default="samtools"
}

bwaMemAligner Parameters (object):
--bwaMemAligner
{
    container_version                   docker container version, defaults to unset
    cpus                                cpus for bwaMemAligner container, defaults to cpus parameter
    mem                                 memory (GB) for bwaMemAligner container, defaults to mem parameter
}

bamMergeSortMarkdup Parameters (object):
--bamMergeSortMarkdup
{
    container_version                   docker container version, defaults to unset
    output_format                       options are ['cram', 'bam'], defaults to 'cram'
    markdup                             perform markdpulicate or not, defaults to true
    lossy                               generate lossy cram or not, defaults to false
    cpus                                cpus for bamMergeSortMarkdup container, defaults to cpus parameter
    mem                                 memory (GB) for bamMergeSortMarkdup container, defaults to mem parameter
}

payloadGenDnaAlignment (object):
--payloadGenDnaAlignment
{
    container_version                   docker container version, defaults to unset
    cpus                                cpus for align container, defaults to cpus parameter
    mem                                 memory (GB) for align container, defaults to mem parameter
}

Upload Parameters (object):
--upload
{
    song_container_version              song docker container version, defaults set below
    score_container_version             score docker container version, defaults set below
    song_url                            song url for upload process (defaults to main song_url param)
    score_url                           score url for upload process (defaults to main score_url param)
    api_token                           song/score API token for upload process (defaults to main api_token param)
    song_cpus                           cpus for song container, defaults to cpus parameter
    song_mem                            memory (GB) for song container, defaults to mem parameter
    score_cpus                          cpus for score container, defaults to cpus parameter
    score_mem                           memory (GB) for score container, defaults to mem parameter
    score_transport_mem                 memory (GB) for score_transport, defaults to mem parameter
    extract_cpus                        cpus for extract container, defaults to cpus parameter
    extract_mem                         memory (GB) extract score container, defaults to mem parameter
}

*/

params.study_id = ""
params.analysis_id = ""
params.ref_genome_gz = ""

params.cpus = 1
params.mem = 1

download_params = [
    'song_container_version': '4.0.0',
    'score_container_version': '3.0.1',
    'song_url': params.song_url,
    'score_url': params.score_url,
    'api_token': params.api_token,
    *:(params.download ?: [:])
]

seqDataToLaneBam_params = [
    'reads_max_discard_fraction': -1,
    *:(params.seqDataToLaneBam ?: [:])
]

bwaMemAligner_params = [
    *:(params.bwaMemAligner ?: [:])
]

bamMergeSortMarkdup_params = [
    'output_format': 'cram',
    'markdup': true,
    'lossy': false,
    *:(params.bamMergeSortMarkdup ?: [:])
]

readGroupUBamQC_params = [
    *:(params.readGroupUBamQC ?: [:])
]

payloadGenDnaAlignment_params = [
    *:(params.payloadGenDnaAlignment ?: [:])
]

alignedSeqQC_params = [
    *:(params.alignedSeqQC ?: [:])
]

upload_params = [
    'song_container_version': '4.0.1',
    'score_container_version': '3.0.1',
    'song_url': params.song_url,
    'score_url': params.score_url,
    'api_token': params.api_token,
    *:(params.upload ?: [:])
]

// Include all modules and pass params
include songScoreDownload as download from './song-score-utils/song_score_download' params(download_params)
include "./modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/seq-data-to-lane-bam.0.2.1.0/tools/seq-data-to-lane-bam/seq-data-to-lane-bam.nf" params(seqDataToLaneBam_params)
include "./modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/bwa-mem-aligner.0.1.5.0/tools/bwa-mem-aligner/bwa-mem-aligner.nf" params(bwaMemAligner_params)
include "./modules/raw.githubusercontent.com/icgc-argo/data-qc-tools-and-wfs/read-group-ubam-qc.0.1.0.0/tools/read-group-ubam-qc/read-group-ubam-qc.nf" params(readGroupUBamQC_params)
include "./modules/raw.githubusercontent.com/icgc-argo/dna-seq-processing-tools/bam-merge-sort-markdup.0.1.6.0/tools/bam-merge-sort-markdup/bam-merge-sort-markdup.nf" params(bamMergeSortMarkdup_params)
include "./modules/raw.githubusercontent.com/icgc-argo/data-qc-tools-and-wfs/aligned-seq-qc.0.2.0.0/tools/aligned-seq-qc/aligned-seq-qc" params(alignedSeqQC_params)
include "./modules/raw.githubusercontent.com/icgc-argo/data-processing-utility-tools/payload-gen-dna-alignment.0.1.3.0/tools/payload-gen-dna-alignment/payload-gen-dna-alignment.nf" params(payloadGenDnaAlignment_params)
include songScoreUpload as upload from './song-score-utils/song_score_upload' params(upload_params)


workflow DnaAlignment {
    get:
        study_id
        analysis_id
        ref_genome_gz

    main:
        // download files and metadata from song/score (analysis type: sequencing_experiment)
        download(study_id, analysis_id)

        // preprocessing input data (BAM or FASTQ) into read group level unmapped BAM (uBAM)
        seqDataToLaneBam(download.out.song_analysis, download.out.files.collect())

        // use scatter to run BWA alignment for each ubam in parallel
        bwaMemAligner(seqDataToLaneBam.out.lane_bams.flatten(), file(ref_genome_gz),
            Channel.fromPath(getBwaSecondaryFiles(ref_genome_gz), checkIfExists: true).collect(),
            download.out.song_analysis)

        // perform ubam QC
        readGroupUBamQC(bwaMemAligner.out.aligned_bam.flatten())

        // collect aligned lane bams for merge and markdup
        bamMergeSortMarkdup(bwaMemAligner.out.aligned_bam.collect(), file(ref_genome_gz),
            Channel.fromPath(getMdupSecondaryFile(ref_genome_gz), checkIfExists: true).collect())

        // generate payload for aligned seq (analysis type: sequencing_alignment)
        payloadGenDnaAlignment(bamMergeSortMarkdup.out.merged_seq.concat(bamMergeSortMarkdup.out.merged_seq_idx).collect(),
            download.out.song_analysis, [], name, '', workflow.manifest.version)

        // perform aligned seq QC
        alignedSeqQC(payloadGenDnaAlignment.out.alignment_files.flatten().first(), file(ref_genome_gz),
            Channel.fromPath(getAlignedQCSecondaryFiles(ref_genome_gz), checkIfExists: true).collect())

        // upload aligned file and metadata to song/score
        upload(params.study_id, payloadGenDnaAlignment.out.payload, payloadGenDnaAlignment.out.alignment_files.collect())

    emit:
        analysis_id = upload.out.analysis_id
        alignment_files = payloadGenDnaAlignment.out.alignment_files
}


workflow {
    DnaAlignment(
        params.study_id,
        params.analysis_id,
        params.ref_genome_gz
    )

    publish:
        DnaAlignment.out.alignment_files to: "outdir", overwrite: true
}

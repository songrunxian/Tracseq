#!/bin/bash
#

#step1 数据准备:
ln -s /share/liuqi/runxian/TRAC-Seq/rawdata/*.sra .
bowtie-build chrMT_trna_ref.fa chrMT_trna_ref.fa

curdir=`pwd`
mkdir clean_outdir
mkdir motif_out

for i in `find ${curdir} -name "*.sra"`
do
	filename=`basename ${i}`
	samplename=${filename%%.*}
	fastq-dump ${i}.sra
	fastqc ${i}.fastq
	#length 可能要调整
	trim_galore ${i}.fastq --phred33 -a AGATCGGAAGAGCACA -length 25 -q 20 --stringency 1 -o clean_outdir
	bowtie -a -m 50 -v 3 --best --strata -S ${curdir}/chrMT_trna_ref.fa clean_outdir/${i}_trimmed.fq ${i}_trimmed.sam
	samtools view -bS ${i}_trimmed.sam > ${i}_trimmed.bam
	samtools sort ${i}_trimmed.bam -o ${i}_trimmed.sort.bam #文章中少了.bam
	samtools index ${i}.sort.bam
	bedtools genomecov -ibam ${i}_trimmed.sort.bam -bg > ${i}_trimmed.sort.bam.bg
	Rscript cleavage_score.r ${curdir}/chrMT_trna_ref.fa ${curdir}/chrMT_trna_ref.gff ???.bam ???.bam 分类
	meme for_motif.fasta -mod zoops -dna -nmotifs 3 -maxw 7 -o motif_out
	##表达分析可用本文，或者featurcount，或适度调整
done


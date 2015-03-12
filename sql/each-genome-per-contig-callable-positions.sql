SELECT
  sample.id,
  chromosome,
  contig.len,
  num_SNVs,
  num_REFs,
  (num_SNVs + num_REFs) AS num_called_point_pos,
  (num_SNVs + num_REFs) / contig.len AS prop_w_point_ino,
  (contig.len - (num_SNVs + num_REFs)) AS pos_no_point_info
FROM
  (
  SELECT
    call.call_set_name AS sample.id,
    reference_name AS chromosome,
    assembly.LENGTH AS contig.len,
    SUM(IF (genotype!="0/0" AND call.FILTER="PASS" AND VAR_type="SNV" , 1, 0)) AS num_SNVs,
    SUM(IF (genotype=="0/0", (end - start), 0)) AS num_REFs
  FROM
    (
    SELECT
      call.call_set_name,
      reference_name,
      start,
      end,
      reference_bases,
      GROUP_CONCAT(alternate_bases) WITHIN RECORD AS alternate_bases,
      GROUP_CONCAT(STRING(call.genotype), "/") WITHIN call AS genotype,
      IF(LENGTH(reference_bases)=1 AND LENGTH(alternate_bases)=1, "SNV", "INDEL") AS VAR_type,
      call.FILTER
    FROM 
      FLATTEN([gbsc-gcp-project-mvp:va_aaa_pilot_data.5_genome_test_gvcfs], call.call_set_name)
    ) AS geno
    JOIN 
      [stanford.edu:gbsc-stanford-google:resources.hg19_Assembly_BinaRuns] AS assembly
    ON
      geno.reference_name = assembly.CHR
  GROUP BY
    sample.id,
    chromosome,
    contig.len
  )
ORDER BY
  chromosome,
  sample.id

SHELL=/bin/bash -o pipefail

#Define path for makefile
BASE ?= $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
#Tool used to print variable value
print-% : ; @echo $* = $($*)
YYMONTH ?=2017m10
RUNDIR ?=$(BASE)/output/end-to-end-output

###################################################################################################
#
###################################################################################################
#Run commands on Dev server
###################################################################################################
#run module by module
###############################################################################
## 1% sample data [TEST]
## can be run in module by module only since wrsi module does not work for 1% data 
1pct:
	python run_hve_phase2.py run_batch config/test_config/config_1pct.txt

###############################################################################
#run end to end
###############################################################################
##tiny sample data, run and tie out [TEST]
tiny:
	python run_hve_phase2.py run_batch config/test_config/config_tiny.txt

tiny2csv:
	python run_hve_phase2.py run_batch config/adhoc_config/config_tocsv_tiny.txt

pr_hdata:
	python run_hve_phase2.py run_batch config/adhoc_config/config_preparehdata.txt
pr_hdata_2019m12:
	python run_hve_phase2.py run_batch config/adhoc_config/config_preparehdata_2019m12.txt
###################################################################################################
#Run commands at AWS
###################################################################################################
###############################################################################
## tiny sample data [TEST]
tiny_aws:
	python run_hve_phase2.py run_batch config/test_config/config_tiny_aws.txt
###############################################################################
## 1% sample data [TEST]
1pct_aws:
	python run_hve_phase2.py run_batch config/test_config/config_1pct_aws.txt
###############################################################################
## full data e2e
###############################################################################
full_aws_e2e:
	python run_hve_phase2.py run_batch config/config_full_aws.txt

full_aws_2019m12:
	python run_hve_phase2.py run_batch config/config_full_aws_2019m12.txt

full2csv:
	python run_hve_phase2.py run_batch config/adhoc_config/config_tocsv_aws.txt
full2csv_2019m12:
	python run_hve_phase2.py run_batch config/adhoc_config/config_tocsv_aws_2019m12.txt
rf_report:
	python run_hve_phase2.py run_batch config/adhoc_config/config_rf_report.txt
norm_data:
	python run_hve_phase2.py run_batch config/adhoc_config/config_normalize_data.txt
#################################################################

###############################################################################
#run module by module
###############################################################################
full_word_split:
	python driver.py run_batch configs/word_split.txt

###############################################################################
#format code
###############################################################################
black:
	black -t py37 .
flake8:
	flake8

ip ?= 1
RAW_INPUT ?=/fmacdata/dev/fir/user/fuxin/hve_phase2_raw_input#Input directory used for sample
INPUTDIR ?= $(BASE)/snapshots/all_sample/input/#input directory used for running

BUCKET_V1=aws-sfn01-s3-us-east-1-hve-proof-of-concept
BUCKET_V2=aws-sfn01-s3-us-east-1-emr-hve-hve-dev-lz
BUCKET=aws-sfn01-s3-us-east-1-emr-cvs-cvs-dev
#USDR ?=junyi
USDR ?=junyi

S3_INPUT ?= s3://$(BUCKET_V1)/data/transfers/phase2_full/
#S3_OUTPUT ?= s3://$(BUCKET_V1)/users/$(USDR)1pct_sample/postmatlab/output/
S3_OUTPUT ?= s3://$(BUCKET_V1)/users/$(USDR)/phase2/phase2_full_filters_added/
S3_OUTPUT_TMP ?= s3://$(BUCKET)/users/$(USDR)/phase2/phase2_full/
S3_Parquet ?= s3://$(BUCKET_V1)/users/$(USDR)/parquet/phase2_full/
#S3_REFDIR ?= s3://$(BUCKET)/fmacdata/hve-phase2-tieout/1pct_sas_input_output/postmatlab/output/
S3_REFDIR ?= s3://$(BUCKET)/fmacdata/hve-phase2-tieout/rsdp_sas_output_junyi_run/

#ifeq ($(ip), 1)
#	S3_INPUT ?= s3://$(BUCKET)/data/transfers/tiny_sample/
#	S3_OUTPUT ?= s3://$(BUCKET)/users/$(USDR)/phase2/tiny_sample/
#	S3_Parquet ?= s3://$(BUCKET)/users/$(USDR)/parquet/tiny_sample/
#endif
#S3_INPUT ?= s3://$(BUCKET)/data/transfers/fulldata/
#S3_OUTPUT ?= s3://$(BUCKET)/users/$(USDR)/parquet/fulldata/

REFDIR ?= /fmacdata/dev/fir/user/fuxin/ref_phase2/end-to-end-output-sample_p3/
REFPYDIR ?= $(REFDIR)

S3Raw ?= s3://$(BUCKET)/data/transfers/fulldata/
#to use ip=1, just type make ip=1 
ifeq ($(ip), 1)
	INPUTDIR := $(BASE)/snapshots
	REFDIR := $(BASE)/snapshots
    RUNDIR := $(BASE)/output/end-to-end-output
endif
tt:
	@echo "INPUTDIR:" $(INPUTDIR)
	@echo "REFDIR:  " $(REFDIR)
	@echo "RUNDIR:  " $(RUNDIR)
######################################################################################################
#Prepare data
####################################################################################################
steps/sas2parquet:
	if [ $(ip) == 0 ]; then \
	echo "Error! Converting from sas output to parquet only applies to sas module level tie out!" ;\
	else \
	python adhoc/sas_csv2parquet.py $(REFDIR) $(REFPYDIR); fi


steps/sample:steps/init
	# first, copy all the input data into run directory
	python adhoc/sample_input.py $(RAW_INPUT) $(INPUTDIR) --overwrite-inputs
	find . -type f -print0 | xargs -0 ls -lh | grep -v .git > $@
#convert raw input data from csv to parquet
steps/copy_data: steps/init
	if [ ! -d "$(RUNDIR)" ]; then mkdir -p $(RUNDIR); fi
	#rsync -ai --progress $(INPUTDIR) $(RUNDIR)
	#python adhoc/convert_to_parquet.py $(INPUTDIR) $(RUNDIR) --bz2
	python adhoc/convert_to_parquet.py $(INPUTDIR) $(RUNDIR)
	find . -type f -print0 | xargs -0 ls -lh | grep -v .git > $@

steps/to_parquet_sample: steps/copy_data
	# first, copy all the input data into run directory
	#zip -r hve_phase2.zip *
	python adhoc/convert_to_parquet.py $(RUNDIR) $(RUNDIR)
	find . -type f -print0 | xargs -0 ls -lh | grep -v .git > $@

######################################################################################################
#Conduct end to end run
######################################################################################################
steps/run_rsdp:steps/copy_data
	# first, copy all the input data into run directory
	python rsdp/run_rsdp.py $(RUNDIR) $(RUNDIR) $(YYMONTH)
	find . -type f -print0 | xargs -0 ls -lh | grep -v .git > $@

steps/run_rs:steps/run_rsdp
	python rs/run_rs.py $(RUNDIR) $(RUNDIR) $(YYMONTH)
	find . -type f -print0 | xargs -0 ls -lh | grep -v .git > $@

# steps/run_wrsi: export LD_LIBRARY_PATH=/usr/local/hve/anaconda/envs/.pkgs/mkl-11.3.1-0/lib:$LD_LIBRARY_PATH
# steps/run_wrsi: export LD_LIBRARY_PATH=/usr/local/hve/user/jim/sparse/SuiteSparse/lib:$LD_LIBRARY_PATH
steps/run_wrsi:steps/run_rs
	if [ -d "$(RUNDIR)/wrsi_noreo/data/rs/2017m10/v5/state/csvindex" ]; then rm -rf $(RUNDIR)/wrsi_noreo/data/rs/2017m10/v5/state/csvindex ; fi
	if [ -d "$(RUNDIR)/wrsi_refactor" ]; then rm -rf $(RUNDIR)/wrsi_refactor ; fi
	# /usr/local/hve/anaconda/envs/sparse/bin/python rs/rs/wrsi/reg_main.py 
	python run_wrsi.py \
	$(RUNDIR) \
	$(RUNDIR) $(YYMONTH)
	find . -type f -print0 | xargs -0 ls -lh | grep -v .git > $@

steps/postmatlab:steps/run_wrsi
	python postmatlab/run_postmatlab.py $(RUNDIR) $(RUNDIR) $(YYMONTH)
	find . -type f -print0 | xargs -0 ls -lh | grep -v .git > $@

steps/wrsi_2unit:steps/postmatlab
	python wrsi_2unit/run_wrsi_2unit.py $(RUNDIR) $(RUNDIR) $(YYMONTH)
	find . -type f -print0 | xargs -0 ls -lh | grep -v .git > $@

steps/mlsdata_split:steps/run_rsdp
	python mls_split/run_mls_split.py $(RUNDIR) $(RUNDIR) $(YYMONTH)
	find . -type f -print0 | xargs -0 ls -lh | grep -v .git > $@

tests/mlsdata_split:
	pytest -s mls_split/test/test_ref/test_csv.py -k test_all
	find . -type f -print0 | xargs -0 ls -lh | grep -v .git > $@

# steps/mlsdata_combine:steps/mlsdata_split
	# python mls_combine/run_mls_combine.py $(RUNDIR) $(RUNDIR) $(YYMONTH)
	# find . -type f -print0 | xargs -0 ls -lh | grep -v .git > $@
steps/mlsdata_combine:steps/mlsdata_split
	# spark-submit --master local[16] 
	python run_mls_combine.py $(RUNDIR) $(RUNDIR) $(YYMONTH)
	find . -type f -print0 | xargs -0 ls -lh | grep -v .git > $@

tests/mls_combine:
	pytest -s mls_combine/test/test_ref/test_ref.py -k test_all

steps/markseed:steps/mlsdata_combine steps/wrsi_2unit
	python markseeds/run_markseeds.py $(RUNDIR) $(RUNDIR) $(YYMONTH)
	find . -type f -print0 | xargs -0 ls -lh | grep -v .git > $@

steps/predataprep:steps/markseed
	python predataprep/run_predataprep.py $(RUNDIR) $(RUNDIR) $(YYMONTH)
	find . -type f -print0 | xargs -0 ls -lh | grep -v .git > $@

steps/dataprep:steps/predataprep
	# python dataprep/run_dataprep.py $(RUNDIR) $(RUNDIR) $(YYMONTH)
	python run_dataprep.py $(RUNDIR) $(RUNDIR) $(YYMONTH)
	find . -type f -print0 | xargs -0 ls -lh | grep -v .git > $@

tests/dataprep:
	pytest -s dataprep/test/test_ref/test_ref.py -k test_all

steps/hdata:steps/dataprep
	# python hdata/run_hdata.py $(RUNDIR) $(RUNDIR) $(YYMONTH)
	python run_hdata.py $(RUNDIR) $(RUNDIR) $(YYMONTH)
	find . -type f -print0 | xargs -0 ls -lh | grep -v .git > $@

tests/hdata:
	pytest -s hdata/test/test_ref/test_ref.py -k test_all

all: steps/hdata

clean_all:
	rm -rf steps $(RUNDIR)/*
clean_rsdp:
	if [ -f "steps/run_rsdp" ]; then rm steps/run_rsdp ; fi
	python 	adhoc/clean_output.py $(RUNDIR) rsdp
clean_mlsdata_split:
	if [ -f "steps/mlsdata_split" ]; then rm steps/mlsdata_split ; fi
	python 	adhoc/clean_output.py $(RUNDIR) mlsdata_split	
clean_mlsdata_combine:
	if [ -f "steps/mlsdata_combine" ]; then rm steps/mlsdata_combine ; fi
	python 	adhoc/clean_output.py $(RUNDIR) mlsdata_combine	
clean_dataprep:
	if [ -f "steps/dataprep" ]; then rm steps/dataprep ; fi 
	if [ -f "steps/predataprep" ]; then rm steps/predataprep ; fi
	python 	adhoc/clean_output.py $(RUNDIR) dataprep
##############################################################################
#Run module by module at AWS EMR
##############################################################################

to_parquet_emr:
	# first, copy all the input data into run directory
	aws s3 rm --recursive $(S3_Parquet)
	zip -r hve_phase2.zip * -x output
	spark-submit --master yarn --deploy-mode client  --driver-memory 15g \
	--num-executors 200 --executor-cores 4 \
    --py-files hve_phase2.zip adhoc/convert_to_parquet.py $(S3_INPUT) $(S3_Parquet) --bz2
#	spark-submit --master yarn --deploy-mode client  --driver-memory 15g \
	--executor-cores 2 --executor-memory 30g \
    --py-files hve_phase2.zip adhoc/convert_to_parquet.py $(S3_INPUT) $(S3_Parquet) --bz2

to_parquet_county_emr:
	# first, copy all the input data into run directory
	# aws s3 rm --recursive $(S3_Parquet)
	zip -r hve_phase2.zip * -x output
	spark-submit --master yarn --deploy-mode client  --driver-memory 15g \
	--num-executors 200 --executor-cores 2 --executor-memory 30g \
    --py-files hve_phase2.zip adhoc/convert_to_parquet_county.py $(S3_INPUT) $(S3_Parquet) --bz2

to_parquet_sample_emr:
	# first, copy all the input data into run directory
	zip -r hve_phase2.zip * -x output
	spark-submit --master yarn --deploy-mode client  --driver-memory 15g \
	--py-files hve_phase2.zip adhoc/convert_to_parquet.py $(S3_INPUT) $(S3_Parquet) --bz2
#	spark-submit --master yarn --num-executors 4 --executor-cores 2 \
#--driver-memory 10g --py-files adhoc.zip,shared.zip adhoc/convert_to_parquet.py $(S3_INPUT) $(S3_OUTPUT)

cp_parquet_emr:
	# first, copy all the input data into run directory
	aws s3 rm --recursive $(S3_OUTPUT)
	aws s3 cp --recursive $(S3_Parquet) $(S3_OUTPUT)

run_rsdp_emr:
#	zip -r hve_phase2.zip * -x output
	spark-submit --deploy-mode client --master yarn --driver-memory 64g \
	--executor-cores 2 --executor-memory 10g \
	--conf spark.driver.maxResultSize=10g \
	rsdp/run_rsdp.py $(S3_OUTPUT) $(S3_OUTPUT) $(YYMONTH) --overwrite-inputs

test_rsdp_emr:
	if [ $(ip) == 0 ]; then \
        pytest -s test/test_rsdp.py -k test_full --outdir $(S3_OUTPUT) --refdir $(S3_REFDIR) --runmonth $(YYMONTH) ;\
        else \
        pytest -s test/test_rsdp.py -k test__1 --outdir $(S3_OUTPUT) --refdir $(S3_REFDIR) --runmonth $(YYMONTH) ; fi



run_rs_emr:
	zip -r hve_phase2.zip *
	spark-submit --deploy-mode client --master yarn --driver-memory 15g \
	--executor-cores 2 --executor-memory 10g \
	--conf spark.driver.maxResultSize=10g \
	--conf spark.kryoserializer.buffer.max=256m \
	--py-files hve_phase2.zip \
	rs/run_rs.py $(S3_OUTPUT) $(S3_OUTPUT) $(YYMONTH)

run_wrsi_emr:
	zip -r hve_phase2.zip *
	spark-submit --deploy-mode client --master yarn --driver-memory 15g \
	--num-executors 20 --executor-cores 1 --executor-memory 100g \
	--py-files hve_phase2.zip \
	--conf spark.driver.maxResultSize=10g \
	run_wrsi.py $(S3_OUTPUT) $(S3_OUTPUT) $(YYMONTH)

run_postmatlab_emr:
	zip -r hve_phase2.zip *
	spark-submit --deploy-mode client --master yarn --driver-memory 15g \
	--py-files hve_phase2.zip \
	--conf spark.driver.maxResultSize=10g \
	--conf spark.kryoserializer.buffer.max=256m \
	postmatlab/run_postmatlab.py $(S3_OUTPUT) $(S3_OUTPUT) $(YYMONTH)

test_postmatlab_emr:
	if [ $(ip) == 0 ]; then \
        pytest -s test/test_postmatlab.py -k test_postmatlab_reg --outdir $(S3_OUTPUT) --refdir $(S3_REFDIR) --runmonth $(YYMONTH) ;\
        else \
        pytest -s test/test_postmatlab.py -k test_postmatlab_1 --outdir $(S3_OUTPUT) --refdir $(S3_REFDIR) --runmonth $(YYMONTH) ; fi

run_wrsi2unit_emr:
	zip -r hve_phase2.zip *
	spark-submit --deploy-mode client --master yarn --driver-memory 200g \
	--py-files hve_phase2.zip \
	--conf spark.driver.maxResultSize=10g \
	--conf spark.kryoserializer.buffer.max=256m \
	wrsi_2unit/run_wrsi_2unit.py $(S3_OUTPUT) $(S3_OUTPUT) $(YYMONTH)

run_mlsdata_split_emr:
	zip -r hve_phase2.zip *
	spark-submit --deploy-mode client --master yarn --driver-memory 15g \
	--py-files hve_phase2.zip \
	--conf spark.driver.maxResultSize=10g \
	--conf spark.kryoserializer.buffer.max=256m \
	  run_mls_split.py $(S3_OUTPUT) $(S3_OUTPUT) $(YYMONTH)

run_mlsdata_combine_emr:
	zip -r hve_phase2.zip *
	spark-submit --deploy-mode client --master yarn --driver-memory 15g \
	--executor-cores 40 --conf spark.executor.memoryOverhead=150g --executor-memory 580g \
	--conf spark.driver.maxResultSize=10g \
	--conf spark.kryoserializer.buffer.max=256m \
	--py-files hve_phase2.zip \
	  run_mls_combine.py $(S3_OUTPUT) $(S3_OUTPUT) $(YYMONTH)

run_markseed_emr:
	zip -r hve_phase2.zip *
	spark-submit --deploy-mode client --master yarn --driver-memory 600g \
	--executor-cores 2 --executor-memory 50g \
	--conf spark.driver.maxResultSize=300g \
	--conf spark.kryoserializer.buffer.max=256m \
	--py-files hve_phase2.zip \
	  markseeds/run_markseeds.py $(S3_OUTPUT) $(S3_OUTPUT) $(YYMONTH)

run_predataprep_emr:
	zip -r hve_phase2.zip *
	spark-submit --deploy-mode client --master yarn --driver-memory 100g \
	--executor-cores 30 --conf spark.executor.memoryOverhead=150g --executor-memory 600g \
	--conf spark.driver.maxResultSize=50g \
	--py-files hve_phase2.zip \
	  run_predataprep.py $(S3_OUTPUT) $(S3_OUTPUT) $(YYMONTH)

run_dataprep_emr:
	zip -r hve_phase2.zip *
	spark-submit --deploy-mode client --master yarn --driver-memory 50g \
	--executor-cores 30 --conf spark.executor.memoryOverhead=150g --executor-memory 600g \
	--conf spark.driver.maxResultSize=1g \
	--py-files hve_phase2.zip \
	  run_dataprep.py $(S3_OUTPUT) $(S3_OUTPUT) $(YYMONTH)

# --executor-cores 40 --conf spark.executor.memoryOverhead=150g --executor-memory 580g appr suceeded slow 
# --executor-cores 4 --conf spark.executor.memoryOverhead=25g --executor-memory 5g failed oom 
run_hdata_emr:
	zip -r hve_phase2.zip *
	spark-submit --deploy-mode client --master yarn --driver-memory 5g \
	--executor-cores 30 --conf spark.executor.memoryOverhead=150g --executor-memory 600g \
	--py-files hve_phase2.zip \
	  run_hdata.py $(S3_OUTPUT) $(S3_OUTPUT) $(YYMONTH)

test_hdata_emr:
	pytest -s test/test_hdata.py -k test_hdata_1 --outdir $(S3_OUTPUT_TMP) --refdir $(S3_REFDIR)/sas_full_hdata_output --runmonth $(YYMONTH)


#--executor-cores 2 --executor-memory 30g --conf spark.driver.maxResultSize=10g failed oom

run_all_emr: cp_parquet_emr run_rsdp_emr run_rs_emr run_wrsi_emr run_postmatlab_emr \
	         run_wrsi2unit_emr run_mlsdata_split_emr run_mlsdata_combine_emr \
			 run_markseed_emr run_predataprep_emr run_dataprep_emr run_hdata_emr

##############################################################################
#Run module by module at premise server, specify input data directory first
##############################################################################
run_rsdp:steps/copy_data
	python rsdp/run_rsdp.py $(REFDIR)/rsdp/input $(RUNDIR) $(YYMONTH) --overwrite-inputs --sasio
	# python rsdp/run_rsdp.py $(RUNDIR) $(RUNDIR) $(YYMONTH)
test_rsdp:
	if [ $(ip) == 0 ]; then \
	pytest -s test/test_rsdp.py -k test_sample --outdir $(RUNDIR) --refdir $(REFDIR) --runmonth $(YYMONTH) ;\
	else \
	pytest -s test/test_rsdp.py -k test_1 --outdir $(RUNDIR) --refdir $(REFDIR)/rsdp/output --runmonth $(YYMONTH) ; fi

run_rs:
	python rs/run_rs.py $(REFDIR)/rs/input $(RUNDIR) $(YYMONTH) --sasio
test_rs:
	if [ $(ip) == 0 ]; then \
	pytest -s test/test_rs.py -k test_rs_reg --outdir $(RUNDIR) --refdir $(REFDIR) --runmonth $(YYMONTH) ;\
	else \
	pytest -s test/test_rs.py -k test_rs_1 --outdir $(RUNDIR) --refdir $(REFDIR)/rs/output --runmonth $(YYMONTH) ; fi

#run_wrsi: export LD_LIBRARY_PATH=/usr/local/hve/anaconda/envs/.pkgs/mkl-11.3.1-0/lib:$LD_LIBRARY_PATH
#run_wrsi: export LD_LIBRARY_PATH=/usr/local/hve/user/jim/sparse/SuiteSparse/lib:$LD_LIBRARY_PATH
run_wrsi:steps/copy_data
	# if [ -d "$(RUNDIR)/wrsi_noreo/data/rs/2017m10/v5/state/csvindex" ]; then rm -rf $(RUNDIR)/wrsi_noreo/data/rs/2017m10/v5/state/csvindex ; fi
	# /usr/local/hve/anaconda/envs/sparse/bin/python rs/rs/wrsi/reg_main.py 
	if [ $(ip) == 0 ]; then \
	python run_wrsi.py $(RUNDIR) $(RUNDIR) $(YYMONTH) --overwrite-outputs ;\
	else \
	python run_wrsi.py $(REFDIR)/rs/input $(RUNDIR) $(YYMONTH) --overwrite-inputs; fi
	# python run_wrsi.py $(REFDIR)/rs/input $(RUNDIR) $(YYMONTH) --overwrite-inputs --overwrite-outputs --use-matlab-chol; fi
	# python run_wrsi.py $(REFDIR)/rs/input $(RUNDIR) $(YYMONTH) --overwrite-inputs; fi

test_wrsi:
	if [ $(ip) == 0 ]; then \
	pytest -s test/test_rs.py -k test_wrsi --outdir $(RUNDIR)/wrsi_noreo/data/rs/2017m10/v5/state/csvindex --refdir $(REFDIR)/wrsi_noreo/data/rs/2017m10/v5/state/csvindex ;\
	else \
	pytest -s test/test_rs.py -k test_wrsi_full --outdir $(RUNDIR) --refdir $(REFDIR)/rs/output ; fi

run_postmatlab:
	# wrsi needs to be run with full data
	#cp -r $(REFDIR)/postmatlab/input/wrsi_noreo/data/rs/2017m10/v5/state/csvindex $(RUNDIR)/wrsi_noreo/data/rs/2017m10/v5/state/
	python postmatlab/run_postmatlab.py $(REFDIR)/postmatlab/input $(RUNDIR) $(YYMONTH) --sasio

test_postmatlab:
	if [ $(ip) == 0 ]; then \
	pytest -s test/test_postmatlab.py -k test_postmatlab_reg --outdir $(RUNDIR) --refdir $(REFDIR) --runmonth $(YYMONTH) ;\
	else \
	pytest -s test/test_postmatlab.py -k test_postmatlab_1 --outdir $(RUNDIR) --refdir $(REFDIR)/postmatlab/output --runmonth $(YYMONTH) ; fi

run_wrsi2unit:
	#python wrsi_2unit/run_wrsi_2unit.py $(RUNDIR) $(RUNDIR) $(YYMONTH)
	python wrsi_2unit/run_wrsi_2unit.py $(REFDIR)/wrsi_2unit/input $(RUNDIR) $(YYMONTH) --sasio
test_wrsi2unit:
	if [ $(ip) == 0 ]; then \
	pytest -s test/test_wrsi2unit.py -k test_wrsi2unit_reg --outdir $(RUNDIR) --refdir $(REFDIR) --runmonth $(YYMONTH) ;\
	else \
	pytest -s test/test_wrsi2unit.py -k test_wrsi2unit_1 --outdir $(RUNDIR) --refdir $(REFDIR)/wrsi_2unit/output --runmonth $(YYMONTH) ; fi

run_mlssplit:
	python run_mls_split.py $(REFDIR)/mlsdata_split/input $(RUNDIR) $(YYMONTH) --overwrite-inputs --sasio 
test_mlssplit:
	if [ $(ip) == 0 ]; then \
	pytest -s test/test_mlsdatasplit.py -k test_mlsdatasplit_reg --outdir $(RUNDIR) --refdir $(REFDIR) --runmonth $(YYMONTH) ;\
	else \
	pytest -s test/test_mlsdatasplit.py -k test_mlsdatasplit_1 --outdir $(RUNDIR) --refdir $(REFDIR)/mlsdata_split/output --runmonth $(YYMONTH) ; fi

run_mlscombine:
	# there are two columns fa_listdate/fa_originallistdate
	# with incompatible dtypes, the 1% data ties out
	python run_mls_combine.py $(REFDIR)/mlsdata_combine/input $(RUNDIR) $(YYMONTH) --sasio
test_mlscombine:
	if [ $(ip) == 0 ]; then \
	pytest -s test/test_mlsdatacombine.py -k test_mlsdatacombine_reg --outdir $(RUNDIR) --refdir $(REFDIR) --runmonth $(YYMONTH) ;\
	else \
	pytest -s test/test_mlsdatacombine.py -k test_mlsdatacombine_reg --outdir $(RUNDIR) --refdir $(REFDIR)/mlsdata_combine/output --runmonth $(YYMONTH) ; fi

run_markseed:
	if [ $(ip) == 0 ]; then \
	python markseeds/run_markseeds.py $(RUNDIR) $(RUNDIR) $(YYMONTH) ;\
	else \
	python markseeds/run_markseeds.py $(REFDIR)/markseeds/input $(RUNDIR) $(YYMONTH) --sasio; fi

test_markseed:
	if [ $(ip) == 0 ]; then \
	pytest -s test/test_markseed.py -k test_markseeds_reg --outdir $(RUNDIR) --refdir $(REFDIR) --runmonth $(YYMONTH) ;\
	else \
	pytest -s test/test_markseed.py -k test_markseeds_1 --outdir $(RUNDIR) --refdir $(REFDIR)/markseeds/output --runmonth $(YYMONTH) ; fi

run_predataprep:
	python run_predataprep.py $(REFDIR)/dataprep/input $(RUNDIR) $(YYMONTH) --sasio --overwrite-inputs --overwrite-refactors
	# python predataprep/run_predataprep.py $(REFDIR)/dataprep/input $(RUNDIR) $(YYMONTH) --sasio --overwrite-inputs

run_dataprep:
	python run_dataprep.py $(RUNDIR) $(RUNDIR) $(YYMONTH) --sasio

test_dataprep:
	if [ $(ip) == 0 ]; then \
	pytest -s test/test_dataprep.py -k test_dataprep_reg --outdir $(RUNDIR) --refdir $(REFDIR) --runmonth $(YYMONTH) ;\
	else \
	pytest -s test/test_dataprep.py -k test_dataprep_1 --outdir $(RUNDIR) --refdir $(REFDIR)/dataprep/output --runmonth $(YYMONTH) ; fi

run_hdata:
	python run_hdata.py $(REFDIR)/hdata/input $(RUNDIR) $(YYMONTH) --sasio --overwrite-inputs
test_hdata:
	if [ $(ip) == 0 ]; then \
	pytest -s test/test_hdata.py -k test_hdata_reg --outdir $(RUNDIR) --refdir $(REFDIR) --runmonth $(YYMONTH) ; \
	else \
	pytest -s test/test_hdata.py -k test_hdata_1 --outdir $(RUNDIR) --refdir $(REFDIR)/hdata/output --runmonth $(YYMONTH) ; fi
###############################################################################
# Specifiy model version number
###############################################################################

V=3_1_0

###############################################################################
# Packaging
###############################################################################

hve.tar.gz: force
	rm -rf package/code-tmp
	mkdir -p package/code-tmp
	git archive --prefix hve/ HEAD rf/bin rf/rfmain rf/rfmodel rf/run_rf.py rf/run_cvs.bash rf/run_rf_aws.py | tar x -C package/code-tmp
	git cat-file commit HEAD > package/code-tmp/.gitcommit
	chmod 654 package/code-tmp/hve/rf/bin/rf
	cd package/code-tmp/hve/rf && zip -r hve_rf.zip rfmain rfmodel && cd ../../../../
	cd package/code-tmp && tar zcvpf ../$@ hve .gitcommit
	rm -rf package/code-tmp

hve-dev-config.tar.gz: force
	rm -rf package/config-tmp
	mkdir -p package/config-tmp/hve
	cp -R rf/config/dev package/config-tmp/hve/rf
	chmod 755 package/config-tmp/hve
	chmod 644 package/config-tmp/hve/*
	chmod -R a+rX package/config-tmp/hve
	cd package/config-tmp && tar zcvpf ../$@ hve/*
	rm -rf package/config-tmp

hve-prod-config.tar.gz: force
	rm -rf package/config-tmp
	mkdir -p package/config-tmp/hve
	cp -R rf/config/prod package/config-tmp/hve/rf
	chmod 755 package/config-tmp/hve
	chmod 644 package/config-tmp/hve/*
	chmod -R a+rX package/config-tmp/hve
	cd package/config-tmp && tar zcvpf ../$@ hve/*
	rm -rf package/config-tmp

hve-dev-jil.tar.gz: force
	rm -rf package/hve-dev-jil
	mkdir -p package/hve-dev-jil
	cp rf/autosys/dev/* package/hve-dev-jil
	cp rf/autosys/util/delete_all_jobs.jil package/hve-dev-jil
	cd package && tar zcvpf $@ hve-dev-jil && rm -rf hve-dev-jil

hve-prod-jil.tar.gz: force
	rm -rf package/hve-prod-jil
	mkdir -p package/hve-prod-jil
	cp rf/autosys/prod/* package/hve-prod-jil
	cp rf/autosys/util/delete_all_jobs.jil package/hve-prod-jil
	cd package && tar zcvpf $@ hve-prod-jil && rm -rf hve-prod-jil

clean_package:
	rm -rf package

package: clean_package hve.tar.gz \
	hve-dev-config.tar.gz hve-prod-config.tar.gz \
	hve-dev-jil.tar.gz hve-prod-jil.tar.gz


.PHONY: force

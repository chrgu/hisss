# Snakemake workflow to align reads to one or more 
# genomic sequences and produce useful outputs including 
# coverage maps and summary tables.
#
# See the README.md for more information.
#
# Authors: Louis Taylor and Arwa Abbas

# Setup

OUTPUT_DIR = str(config["io"]["output"])
LOCAL_DATA_DIR = str(config["io"]["data"])
TARGETS = str(config["align"]["targets"])
DATA_DIR = str(config["io"]["output"]+"/download")

# Rules

un = "un"*int(not config["io"]["paired"]) # use paired or unpaired rule versions

try:
	if config["study_metadata"]["repo"] == 'sra':
		# trust repository metadata over user
		try:
			un = "un"*int(not config["study_metadata"]["paired"])
		except KeyError:
			raise KeyError("couldn't find paired status in SRA metadat--are you using an old config file?")
		include: "rules/sra_" + un + "paired.rules"
		print("using " + un + "paired data from SRA")

	elif config["study_metadata"]["repo"] == 'mgrast':
		try:
			un = "un"*int(not config["study_metadata"]["paired"])
		except KeyError:
			raise KeyError("couldn't find paired status in SRA metadat--are you using an old config file?")
		include: "rules/mgrast_" + un + "paired.rules"
		print("using " + un + "paired data from MG-RAST")

	else:
		raise KeyError("trying to use an unknown repository: "+str(config["study_metadata"]["repo"]))
except KeyError as e:
	print(str(e) + "not found.")
	print("using local " + un + "paired data")
	include: "rules/local_data_"+ un +"paired.rules"

include: "rules/align_" + un + "paired.rules"

include: "rules/process_alignment.rules"

include: "rules/variants.rules"

include: "rules/summary.rules"

include: "rules/plot.rules"

rule all:
	input:
		expand(rules.pull_variants.output, sample = config['samples']),
		rules.all_summary.output,
		rules.all_plot.output,


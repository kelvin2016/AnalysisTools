#!/usr/bin/env Rscript

###############################################################################

library('getopt');
options(useFancyQuotes=F);
options(width=120);

params=c(
	"input_list_file", "l", 2, "character",
	"merge_col_name", "c", 2, "character",
	"output", "o", 1, "character"
);

opt=getopt(spec=matrix(params, ncol=4, byrow=TRUE), debug=FALSE);
script_name=unlist(strsplit(commandArgs(FALSE)[4],"=")[1])[2];

usage = paste(
	"\nUsage:\n", script_name, "\n",
	"	-l <input, text file with list of target files>\n",
	"	-c <column name to merge by, e.g. sample_id or subject_id>\n",
	"	-o <output tab_separated column data file>\n",
	"\n",
	"This script will read in each of the input files specified\n",
	"in the list, and join them all together based on the specified\n",
	"column.\n",
	"\n",
	"Note that this will not work if the column to merge by is not\n",
	"a primary key, i.e. if there are duplicates.\n",
	"If you want to merge two files, where the column does not contain\n",
	"unique values, then use the merge by map code.\n",
	"\n");

if(
	!length(opt$input_list_file) ||
	!length(opt$merge_col_name) ||
	!length(opt$output)
){
	cat(usage);
	q(status=-1);
}

InputFNameList=opt$input_list_file;
MergeColName=opt$merge_col_name;
OutputFName=opt$output;

target_list=read.table(InputFNameList, as.is=T, sep="\n", header=F, check.names=F,
			comment.char="", quote="")[,1];

cat("Target list of files to merge:\n");
print(target_list);

##############################################################################

load_factors=function(fname, merge_colname){
	factors=data.frame(read.table(fname,  header=TRUE, check.names=FALSE, as.is=T, 
		row.names=merge_colname,
		comment.char="", quote="", sep="\t"));

	#print(factors);

	dimen=dim(factors);
	cat("Rows Loaded: ", dimen[1], "\n");
	cat("Cols Loaded: ", dimen[2], "\n");

	return(factors);
}

write_factors=function(fname, table, merge_colname){

	cnames=c(merge_colname, colnames(table));
	table=cbind(rownames(table), table);
	colnames(table)=cnames;

	dimen=dim(table);
	cat("Rows Exporting: ", dimen[1], "\n");
	cat("Cols Exporting: ", dimen[2], "\n");
	
	write.table(table, fname, quote=F, row.names=F, sep="\t");

}

##############################################################################

num_target_files=length(target_list);

cat("Files to Merge: \n");
names(target_list)=LETTERS[1:length(target_list)];
print(target_list);

loaded_factors=list();
loaded_columns=list();
loaded_numrows=list();
unique_columns=character();

total_rows=0;

all_ids=c();
all_column_names=c();
total_columns=0;

for(i in 1:num_target_files){
	
	cur_fname=target_list[i];
	cat("\nLoading: ", cur_fname, "\n", sep="");
	loaded_factors[[i]]=load_factors(cur_fname, MergeColName);	
	loaded_columns[[i]]=colnames(loaded_factors[[i]]);
	loaded_numrows[[i]]=nrow(loaded_factors[[i]]);

	all_column_names=c(all_column_names, loaded_columns[[i]]);
	all_ids=c(all_ids, rownames(loaded_factors[[i]]));
	total_columns=total_columns+length(loaded_columns[[i]]);
}

#print(loaded_factors);
#print(loaded_columns);
#print(loaded_numrows);

cat("\n\n");
all_ids=sort(unique(all_ids));
cat("All IDs Found:\n");
print(all_ids);
num_ids=length(all_ids);

cat("\n");
cat("Number of Columns across all files (excluding the merge column name/key):", total_columns, "\n");

cat("\n");
uniq_col=unique(all_column_names);
dup_columns=F;
if(length(uniq_col)!=length(all_column_names)){
	cat("*************************************************************************\n");
	cat("WARNING:  Duplicate column names found across files:\n");
	cn_tab=table(all_column_names);
	dups_ix=which(cn_tab>1);
	print(cn_tab[dups_ix]);
	cat("*************************************************************************\n");
	cat("\n");
	dup_columns=T;
}

##############################################################################

combined_columns_matrix=matrix(NA, nrow=num_ids, ncol=total_columns);
rownames(combined_columns_matrix)=all_ids;
colnames(combined_columns_matrix)=all_column_names;

##############################################################################

for(i in 1:num_target_files){

	cat("Working on: ", i, "\n");
	cur_ids=rownames(loaded_factors[[i]]);
	cur_colnames=loaded_columns[[i]];

	for(cn in cur_colnames){
		combined_columns_matrix[cur_ids, cn] =
			loaded_factors[[i]][cur_ids, cn];
	}

}

cat("\n");

#print(combined_columns_matrix);

##############################################################################

write_factors(OutputFName, combined_columns_matrix, MergeColName);

##############################################################################
cat("\n");

if(dup_columns){
	cat("**************************************************************************\n");
	cat("WARNING!!!\n");
	cat("Duplicate Columns Found!\n");
	cat("**************************************************************************\n");
}

cat("\nDone.\n");

print(warnings());
	q(status=0);
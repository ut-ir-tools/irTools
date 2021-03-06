#' Read beneficial uses table from R317-2
#'
#' Note - This is not a fully self-sufficient function. Some substantial manual editing was performed on the file before reading see:
#' @importFrom readr read_fwf
#' @importFrom readr fwf_empty

#' @export
readUses=function(file, col_names = c('Name','1C','2A','2B','3A','3B','3C','3D','3E','4')){

#file="P:/WQ/Integrated Report/IR_2020/standards_UAC_R3172/ben_uses_05232019.txt"
#col_names=c('Name','1C','2A','2B','3A','3B','3C','3D','3E','4')

	name=col_names[1]
	var_names=col_names[2:length(col_names)]
	
	data=suppressWarnings({suppressMessages({
		as.data.frame(read_fwf(file, col_positions=fwf_empty(file, col_names=col_names), skip=1))
	})})
	
	for(n in 1:dim(data)[1]){
		row=data[n,]
		if(row[,7] %in% "BL"){data[n,] = NA}
		if(!is.na(row[,1])){
			if(startsWith(row[,1], "(*)") | substr(row[,1], start = 2, stop = 3) == ". "){
				data[n,] = NA
			}
		}
		if(all(is.na(row[,var_names])) & !is.na(data[n, name])){
			data[n+1,name] = paste(data[n, name], data[n+1, name])
			data[n, name] = NA
		}
	}
	data=data[rowSums(is.na(data)) != ncol(data), ]
	data=tidyr::unite(data, bu_class, sep=', ', 2:10)
	data$bu_class=gsub('NA, ', '', data$bu_class)
	data$bu_class=gsub(', NA', '', data$bu_class)
	return(data)
}

#' @examples
#' file="P:/WQ/Integrated Report/IR_2020/standards_UAC_R3172/ben_uses_05232019.txt"
#' uses=readUses(file)

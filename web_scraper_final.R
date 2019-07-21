library(rvest)
library(dyplr)
library(openxlsx)

get_subsite <- function(url, subdir) read_html(paste(url, "/", subdir, sep=""))
get_info <- function(site, css_selector) sapply(html_nodes(site, css_selector), function(node) trimws(gsub("(\\s{2,})", " ", html_text(node))))
#Map between the info from a given site (determined by a css selector) and the labels of that data on the site.
#If the id_obj or id_data is of type character, it is treated as a CSS selector -- otherwise, it is treated as a vector containing the names.
make_info_map <- function(site, data_obj, id_obj) {
	if(is.character(data_obj))
		data <- get_info(site, data_obj)
	else
		data <- data_obj
	if (is.character(id_obj)) 
		names(data) <- get_info(site, id_obj)
	else 
		names(data) <- id_obj
	return(data)
}
extr_first_match <- function(pattern, string) regmatches(string, regexpr(pattern, string))

get_name <- function(test_url) {
	univ_overview <- read_html(test_url)
	return(list(name = get_info(univ_overview, 
		"h1.hero-heading.flex-media-heading.block-tight.hero-heading.text-tighter.block-tight.flex-media-heading")))
}

get_overview <- function(test_url) {
	univ_overview <- read_html(test_url)
	info_location <- list(location = get_info(univ_overview, "strong.left"))
	info_basic <- make_info_map(univ_overview, 
		"strong:nth-child(2)",
		"div.hero-stats-widget section.hero-stats-widget-stats span:nth-child(1)")
	info <- make_info_map(univ_overview,
		"span.heading-small.text-black.text-tight.block-flush.display-block-for-large-up", 
		"span.subheader.text-smaller.text-muted.text-uppercase.display-block-for-large-up")
	return(c(info_location, info_basic, info))
}

get_indicators <- function(test_url) {
	univ_indicators <- get_subsite(test_url, "rankings")
	info <- make_info_map(univ_indicators, 
		"span.text-strong.flex-medium-4.medium-end", 
		"span.text-coal.flex-medium-8")
	return(info)
}

get_rankings <- function(test_url) {
	univ_rankings <- get_subsite(test_url, "overall-rankings")
	info_base <- html_nodes(univ_rankings, "div.block-flush:nth-child(1)")
	#Extract the rankings from the XML - e.g. "#1"
	#the '(tie)' is not included
	info_rankings <- lapply(info_base, function(node)
		xml_text(xml_find_first(node, "span")))
	#Extract the final subdirectory of each url
	#e.g., 'National Universities'
	info_rankings_id <- lapply(info_base, function(node)
		extr_first_match("[^/]*?$", xml_attr(xml_find_first(node, "a"), "href")))
	info <- info_rankings
	names(info) <- info_rankings_id	
	#Remove premium rankings (no rank provided)
	info <- info[which(info!="")]
	return(info)
}

get_applying <- function(test_url) {
	univ_applying <- get_subsite(test_url, "applying")
	info <- make_info_map(univ_applying, 
		"span.heading-small.text-black.text-tight.block-flush.display-block-for-large-up", 
		"span.subheader.text-smaller.text-muted.text-uppercase.display-block-for-large-up")
	return(info)
}

get_paying <- function(test_url) {
	univ_paying <- get_subsite(test_url, "paying")
	info <- make_info_map(univ_paying, 
		"span.text-strong.flex-medium-4.medium-end span:nth-child(1)", 
		"span.text-coal.flex-medium-8")
	return(info)
}

get_academics <- function(test_url) {
	univ_academics <- get_subsite(test_url, "academics")
	info <- make_info_map(univ_academics, "span.text-strong.flex-medium-4.medium-end span:nth-child(1)","span.text-coal.flex-medium-8")
	info_classes <- make_info_map(univ_academics, "span.bar-percentage-chart__stat", "h5.bar-percentage-chart__heading")
	return(c(info, info_classes))
}

get_student_life <- function(test_url) {
	univ_student_life = get_subsite(test_url, "student-life")
	info <- make_info_map(univ_student_life, "span.text-strong.flex-medium-4.medium-end span:nth-child(1)", "p.block-flush.flex-row span.text-coal.flex-medium-8")
	info_housing <- make_info_map(univ_student_life, "div.text-strong:nth-child(3)", "div.bar-tight:nth-child(2)")
	info_housing_types_base <- get_info(univ_student_life, "div.flex-small-12.flex-medium-12 div.pad-tight")
	if(length(info_housing_types_base)>0){
		info_housing_types_split <- do.call("rbind", strsplit(info_housing_types_base, "\\(|\\)"))
		info_housing_types_split_padded <- apply(info_housing_types_split, 1, "length<-", 2)
		info_housing_types <- as.list(info_housing_types_split_padded[2,])
		names(info_housing_types) <- as.list(info_housing_types_split_padded[1,])
	}
	return(c(info, info_housing, info_housing_types))
}	
gsl <- get_student_life(test_url)

get_services <- function(test_url) {
	univ_services = get_subsite(test_url, "campus-info")
	info_services = make_info_map(univ_services, 
		"span.text-strong.flex-medium-4.medium-end span:nth-child(1)",
		"span.text-coal.flex-medium-8")
	return(info_services)
}

read_univ_data <- function(url) {
	univ_name <- get_name(url)
	print(univ_name$name)
	univ_data <- lapply(
	list(
		Overview = get_overview(url), 
		Indicators = get_indicators(url),
		Rankings = get_rankings(url),
		Paying = get_paying(url), 
		Academics = get_academics(url),
		Student_Life = get_student_life(url),
		Services = get_services(url)),
	function(x) data.frame(append(univ_name, x)))
	return(univ_data)
}


link_list <- read.table("university_info_pages.txt", stringsAsFactors=FALSE)[[1]]
all_univs_data <- lapply(link_list, "read_univ_data")
data_matrix <- do.call("rbind", all_univs_data)
final_table <- apply(data_matrix, 2, "bind_rows")
write.xlsx(final_table, file="final_table_file.xlsx")



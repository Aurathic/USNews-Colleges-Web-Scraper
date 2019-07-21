# USNews-Colleges-Web-Scraper
A web scraper that collects most publicly available information about colleges from USNews.
The result is contained in an Excel file. The information from the 2019 school year is included in this repo.

## Usage
1. Collect a list of USNews links to the colleges from which you want to collect data. (The way I did this was load the 'National Universities' rankings page, then download the site and use a webscraper to extract all the URLs.)
2. In the script, specify the name/location of the list of webpages (currently "university_info_pages.txt"), and the excel file output (currently "final_table_file.xlsx").
3. Run the script.

#### Dependencies
rvestr (for web scraping), dyplr (for dataframe combination), and openxlsx (for Excel file output).

## TODOS
- Remove redundant information (due to a mix-up in the "university_info_pages.txt", all of the colleges were repeated twice.)
- Fix the formatting of the file (specifically converting strings to numerics and the dots in the column headers)
- Add comments
- Add missing information:
  - Information from the 'Computer Resources', 'LD Students' and 'Physically Disabled' subsections from the 'Services' page
  - All of the information on the 'Safety' page 
- Collect Premium-only information (will involve getting in touch with someone with premium account access)

#this script gets the class information of the upcoming terms from U of R and U of S
require 'rubygems'
require 'mechanize'


current_term = 201105

agent = Mechanize.new { |agent|
	agent.user_agent_alias = 'Mac Safari'
}

#goto page
page = agent.get('https://pawnss.usask.ca/banprod/bwckschd.p_disp_dyn_sched')

#select terms
terms = Array.new
term_form=page.forms[0]
select_term = term_form.fields[1]
select_term.options.each do |op|
	if op.to_s.to_i > current_term
		terms.push op
	end
end

csv_head = '"Mode","Institution","Term","Title","Subject","Number","URL"'
out_file = File.new("us_class.csv", "a+")
out_file.write(csv_head)
out_file.close
terms.each do |term_op|
	#fork do
	term_op.tick
	if page = agent.submit(term_form)
		page.forms.each do |cat_form|
			subject_list = cat_form.fields[15]
			subject_list.select_all
			if result_page = agent.submit(cat_form)
				page_str = result_page.root.to_s
				regex_atag = Regexp.new(/<a.*?href\s*=\s*["'](.*?)['"].*?>(\d\d\d\d\d)<\/a>/)
				regex_tr = Regexp.new(/<\/tr>/)
				write_str = ''
				p_mode = nil
				p_institution = nil
				p_term = nil
				p_subject = nil
				p_number = nil
				while (match_atag = regex_atag.match(page_str)) do
					match_tr = regex_tr.match(match_atag.post_match)
					page_str = match_tr.post_match
					class_page = match_tr.pre_match.gsub(/<([^>]+)>/,'')
					institution = 'UofS'
					if term_op.to_s[5].chr == '1' 
						term = "Winter " + term_op.to_s[0..3]
					elsif term_op.to_s[5].chr == '5' 
						term = "Spring " + term_op.to_s[0..3]
					elsif term_op.to_s[5].chr == '7' 
						term = "Summer " + term_op.to_s[0..3]
					elsif term_op.to_s[5].chr == '9' 
						term = "Fall " + term_op.to_s[0..3]
					end
					crn = match_atag[2]
					/(.*?)\s(\d*?)\n/.match(class_page)
					subject = $~[1]
					number = $~[2]
					title = class_page.split("\n")[4]
					mode = class_page.split("\n")[5]
					mode = 'TV' if mode == "TEL"
					url = "https://pawnss.usask.ca/banprod/bwckctlg.p_disp_course_detail?cat_term_in="+term_op.to_s+"&subj_code_in="+subject+"&crse_numb_in="+number

					if (mode == 'WEB' || mode == 'IND' || mode == 'TV') && (p_mode != mode || p_institution != institution || p_term != term || p_subject != subject || p_number != number)
						p_mode = mode
						p_institution = institution
						p_term = term
						p_subject = subject
						p_number = number
						write_str += "\n" + mode + ', ' + institution + ', ' + term + ', ' + title + ', ' + subject + ', ' + number + ', ' + url
					end
				end
				out_file = File.new("us_class.csv", "a+")
				out_file.write(write_str)
				out_file.close
			end
			#puts subject_list.to_s
			#cat_form.fields.each do |field|
			#	puts field.to_s
			#end
			#subject_list.options.each do |op|
			#	puts op.to_s
			#end
		end
	puts term_op.to_s
	end
	#end
end



=begin
link_array = Array.new
link_array.push('https://urcourses.uregina.ca/mod/book/edit.php?id=101232&chapterid=16027')

#pages need to be search
link_array.each do |link|
	page = agent.get(link)
	edit_form = page.forms[0]
	#regex = Regexp.new(/\<img[^>]*src[^>]*\>/)
	regex = Regexp.new(/<img (?![^>]*width)[^>]*>/)
	matchdata = regex.match(edit_form.content)
	while matchdata
		edit_form.content = matchdata.pre_match + matchdata.to_s.chop.chop.chop.sub(/\/tmb/, '') + ' style="width:300px;" />' + matchdata.post_match
		matchdata = regex.match(edit_form.content)
	end
	#puts edit_form.content
	page = agent.submit(edit_form)
end
=end

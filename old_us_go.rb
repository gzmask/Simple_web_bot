#this script gets the class information of the upcoming terms from U of R and U of S
require 'rubygems'
require 'mechanize'


current_term = 201007

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

terms.each do |term_op|
	fork do
		term_op.tick
		if page = agent.submit(term_form)
			page.forms.each do |cat_form|
				subject_list = cat_form.fields[15]
				subject_list.select_all
				if result_page = agent.submit(cat_form)
					#<--------------------here we need to handle the result string
					write_str = '"Mode","Institution","Term","Title","Subject","Number","URL"'
					p_mode = nil
					p_institution = nil
					p_term = nil
					p_subject = nil
					p_number = nil
					result_page.links_with(:href =>/crn_in/).each do |link|
						class_page = agent.get(link.href)
						if class_page.root.to_s.include?("Video Conference")
							mode = 'VC'
						elsif class_page.root.to_s.include?("Televised")
							mode = 'TV'
						elsif class_page.root.to_s.include?("Web Based")
							mode = 'Web'
						elsif class_page.root.to_s.include?("Multimode")
							mode = 'Multimode'
						elsif class_page.root.to_s.include?("Off-campus")
							mode = 'Off Campus'
						elsif class_page.root.to_s.include?("On Campus") && !class_page.root.to_s.include?("On Campus Student Fees")
							mode = 'On Campus'
						elsif class_page.root.to_s.include?("Live Face To Face")
							mode = 'On Campus'
						elsif class_page.root.to_s.include?("Independent Studies")
							mode = 'IND'
						else
							mode = 'Unknown'
						end
						regex = Regexp.new(/\s-\s\d\d\d\d\d/)
							
						if class_page.links[4].text != nil && matchdata = regex.match(class_page.links[4].text)
							#regex to get the title, crn, subject, section
							title = matchdata.pre_match
							crn = matchdata.to_s.gsub(/\s-\s/,'')
							subject = matchdata.post_match.gsub(/\s-\s/, ' ').split(' ')[0]
							number = matchdata.post_match.gsub(/\s-\s/, ' ').split(' ')[1]
							section = matchdata.post_match.gsub(/\s-\s/, ' ').split(' ')[2]
							url = link.href
							institution = 'UofS'
							term = term_op.to_s
							if term[5].chr == '1'
								term = 'Winter ' + term[0..3]
							elsif term[5].chr == '5'
								term = 'Spring ' + term[0..3]
							elsif term[5].chr == '7'
								term = 'Summer ' + term[0..3]
							elsif term[5].chr == '9'
								term = 'Fall ' + term[0..3]
							end
							subject = subject.gsub(/,/, '/')
							title = title.gsub(/,/, '/')
							url = 'https://pawnss.usask.ca' + url
							if mode != 'On Campus' && (p_mode != mode || p_institution != institution || p_term != term || p_subject != subject || p_number != number)
								p_mode = mode
								p_institution = institution
								p_term = term
								p_subject = subject
								p_number = number
								write_str += "\n" + mode + ', ' + institution + ', ' + term + ', ' + title + ', ' + subject + ', ' + number + ', ' + url
							end
							puts mode
							puts institution
							puts term
							puts title
							puts subject
							puts number
							puts url
						end
					end
					out_file = File.new(term_op.to_s+"_classes_US.csv", "w+")
					out_file.write(write_str)
					out_file.close
					#puts result_page.root.to_s
				end
				#puts subject_list.to_s
				#cat_form.fields.each do |field|
				#	puts field.to_s
				#end
				#subject_list.options.each do |op|
				#	puts op.to_s
				#end
			end
		end
	end
end

Process.waitall


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

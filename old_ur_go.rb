#this script gets the class information of the upcoming terms from U of R and U of S
require 'rubygems'
require 'mechanize'


current_term = 201025

agent = Mechanize.new { |agent|
	agent.user_agent_alias = 'Mac Safari'
}

#goto page
page = agent.get('https://banner.uregina.ca/prod/sct/bwckschd.p_disp_dyn_sched')

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
			puts "Page has forms:" + page.forms.length.to_s
			page.forms.each do |cat_form|
				puts cat_form.has_field?('sel_subj').to_s
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
						#regex to get the title, crn, subject, section
						regex = Regexp.new(/\s-\s\d\d\d\d\d/)
						matchdata = regex.match(link.text)
						title = matchdata.pre_match
						crn = matchdata.to_s.gsub(/\s-\s/,'')
						subject = matchdata.post_match.gsub(/\s-\s/, ' ').split(' ')[0]
						number = matchdata.post_match.gsub(/\s-\s/, ' ').split(' ')[1]
						section = matchdata.post_match.gsub(/\s-\s/, ' ').split(' ')[2]
						url = link.href
						institution = 'UofR'
						term = term_op.to_s
						if term[4].chr == '1'
							term = 'Winter ' + term[0..3]
						elsif term[4].chr == '2'
							term = 'Spring ' + term[0..3]
						elsif term[4].chr == '3'
							term = 'Fall ' + term[0..3]
						end
						class_page = agent.get(link.href)
						if class_page.root.to_s.include?("Video Conference")
							mode = 'VC'
						elsif class_page.root.to_s.include?("Independent Study")
							mode = 'IND'
						elsif class_page.root.to_s.include?("Televised")
							mode = 'TV'
						elsif class_page.root.to_s.include?("Web-delivered")
							mode = 'Web'
						elsif class_page.root.to_s.include?("Field Schedule")
							mode = 'Field'
						elsif class_page.root.to_s.include?("Field Trip")
							mode = 'Trip'
						elsif class_page.root.to_s.include?("Practicum Schedule")
							mode = 'Practicum'
						elsif class_page.root.to_s.include?("Internship Schedule")
							mode = 'Internship'
						elsif class_page.root.to_s.include?("Co-op Education")
							mode = 'Coop'
						elsif class_page.root.to_s.include?("On Campus")
							mode = 'On Campus'
						else
							mode = 'Off Campus'
						end

						if class_page.root.to_s.include?("FNUn")
							institution = 'FNUn'
						end
						
						cate_page = agent.get(class_page.links[4].href)
						if cate_page.root.to_s.include?("Televised")
							mode = 'TV'
						elsif cate_page.root.to_s.include?("Directed Reading")
							mode = 'Reading'
						elsif cate_page.root.to_s.include?("Web-Delivered")
							mode = 'Web'
						end
						
						subject = subject.gsub(/,/, '/')
						title = title.gsub(/,/, '/')
						url = 'https://banner.uregina.ca' + class_page.links[4].href
						if mode != 'On Campus' && (p_mode != mode || p_institution != institution || p_term != term || p_subject != subject || p_number != number)
							p_mode = mode
							p_institution = institution
							p_term = term
							p_subject = subject
							p_number = number
							write_str += "\n" + mode + ', ' + institution + ', ' + term + ', ' + title + ', ' + subject + ', ' + number + ', ' + url
						end
						puts '.'
					end
					out_file = File.new(term_op.to_s+"_classes.csv", "w+")
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

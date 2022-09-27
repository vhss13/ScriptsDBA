use msdb
go


Select	j.name [Nome do Job],
		Convert(Varchar(2), jt.step_id) [Step Nr], 
		jt.step_name [Nome do Step], 
		Convert(varchar(10), j.date_created, 101) + ' ' + Convert(varchar(8), j.date_created, 108) [Data de Criação], 
		Convert(varchar(10), j.date_modified, 101) + ' ' + Convert(varchar(8), j.date_modified, 108) [Data de Modificação], 
		case when j.enabled = 1 then 'Sim' else 'Não' end [Job Habilitado ], 
		s.name [Nome do Schedule], 
		j.name [Nome do Job],
		case when s.enabled = 1 then 'Sim' else 'Não' end [Schedule Habilitado], 
		case when s.freq_type = 1 then 'Uma Vez'
			 when s.freq_type = 4 then 'Diário'
			 when s.freq_type = 8 then 'Semanal'
			 when s.freq_type = 16 then 'Mensal'
			 when s.freq_type = 32 then 'Mensal relativo'
			 when s.freq_type = 64 then 'Quando o Agent inicia'
		end [Periodicidade], 
		case  when freq_type = 1 then 'Quando necessário'
		when freq_type = 4 then cast(s.freq_interval as varchar) + ' Dia(s)'
		when freq_type = 8 then case	when s.freq_interval = 127	Then 'Segunda a Segunda'
										when s.freq_interval = 65	Then 'Sábado e Domingo'
										when s.freq_interval = 64	Then 'Sábado'
										when s.freq_interval = 62	Then 'Segunda a Sexta'
										when s.freq_interval = 32	Then 'Sexta'
										when s.freq_interval = 16	Then 'Quinta'
										when s.freq_interval = 8	Then 'Quarta'
										when s.freq_interval = 4	Then 'Terça'
										when s.freq_interval = 2	Then 'Segunda'
										when s.freq_interval = 1	Then 'Domingo'
								else 'Schedulle diferenciado'
								end
		when freq_type = 16 then 'Todo dia ' + cast(s.freq_interval as varchar) + ' de cada mes' end [Execução],
		case	when s.freq_subday_type = 0 then 'Ativado Manualmente'
				when s.freq_subday_type > 1 then 'A cada ' + cast(s.freq_subday_interval as varchar) + 
					case when s.freq_subday_type = 2 then ' segundo(s)'
                         when s.freq_subday_type = 4 then ' minuto(s)'
                         when s.freq_subday_type = 8 then ' hora(s)'
				    end 
				else    
				substring(right('000000'+convert(varchar, s.active_start_time),6), 1, 2)+ ':' + substring(right('000000'+convert(varchar, s.active_start_time),6),3,2)
				end [Freqüência/Horário],
		case when js.next_run_time <> 0 then 
		substring(convert(varchar, js.next_run_date), 7, 2)+ '/' + substring(convert(varchar, js.next_run_date),5,2) + '/' + convert(varchar, left(js.next_run_date , 4)) + ' ' +
		substring(right('000000'+convert(varchar, js.next_run_time),6), 1, 2)+ ':' + substring(right('000000'+convert(varchar, js.next_run_time),6),3,2)
		else 'NA' 
		end [Próxima Execução], 
		case when jt.last_run_date = 0 then 'sem histórico'
		else	right(cast(jt.last_run_date as varchar), 2) + '/' +
				substring(cast(jt.last_run_date as varchar), 5, 2) + '/' +
				left(cast(jt.last_run_date as varchar), 4) + ' ' +
				left(right('0' + cast(jt.last_run_time as varchar), 6), 2) + ':' + 
				substring(right('0' + cast(jt.last_run_time as varchar), 6), 3, 2) + ':' + 
				right(cast(jt.last_run_time as varchar), 2)
		end [Última Execução],
		case when jt.last_run_date = 0 then 'sem histórico'
		else	reverse(STUFF(STUFF(reverse(case when len(cast(jt.last_run_duration as varchar)) < 6 then 
				right('00000'+cast(jt.last_run_duration as varchar), 6) else 
				cast(jt.last_run_duration as varchar) end), 3, 0, ':'), 6, 0, ':'))
	    end [Tempo Última Execução],
		case when jt.last_run_outcome = 1 then 'OK'
			 when jt.last_run_outcome = '' and jt.last_run_date = 0 then 'Sem histórico'
		else 'ERROR !!!' end [Status],
		case when jt.last_run_date = 0 then 'sem histórico'
		else Substring(jh.message,1,233)
		end MENSAGEM		
from msdb..sysjobs j with (nolock)
inner  join msdb..sysjobsteps jt with (nolock) on j.job_id = jt.job_id
left join msdb..sysjobschedules js with (nolock) on j.job_id = js.job_id
left join msdb..sysschedules s with (nolock) on js.schedule_id = s.schedule_id
left  join msdb..sysjobhistory jh on jh.job_id = j.job_id and jh.step_id = jt.step_id and jh.run_date = jt.last_run_date and jh.run_time = jt.last_run_time
where j.enabled = 1
order by j.name

Select	j.name [Nome do Job],
		Convert(Varchar(2),
		jt.step_id) [Step Nr],
		jt.step_name [Nome do Step],
		Convert(varchar(10), j.date_created, 101) + ' ' +
		Convert(varchar(8), j.date_created, 108) [Data de Cria��o],
		Convert(varchar(10), j.date_modified, 101) + ' ' +
		Convert(varchar(8), j.date_modified, 108) [Data de Modifica��o],
		case when j.enabled = 1 then 'Sim' else 'N�o' end [Job Habilitado ],
		js.name [Nome do Schedule],
		j.name [Nome do Job],
		case when js.enabled = 1 then 'Sim' else 'N�o' end [Schedule Habilitado],
		case when js.freq_type = 1 then 'Uma Vez'
			 when js.freq_type = 4 then 'Di�rio'
			 when js.freq_type = 8 then 'Semanal'
			 when js.freq_type = 16 then 'Mensal'
			 when js.freq_type = 32 then 'Mensal relativo'
			 when js.freq_type = 64 then 'Quando o Agent inicia'
		end [Periodicidade],
		case  when freq_type = 1 then 'Quando necess�rio'
			  when freq_type = 4 then cast(js.freq_interval as varchar) + ' Dia(s)'
			  when freq_type = 8 then case	when js.freq_interval = 127	Then 'Segunda a Segunda'
							when js.freq_interval = 65	Then 'S�bado e Domingo'
							when js.freq_interval = 64	Then 'S�bado'
							when js.freq_interval = 62	Then 'Segunda a Sexta'
							when js.freq_interval = 32	Then 'Sexta'
							when js.freq_interval = 16	Then 'Quinta'
							when js.freq_interval = 8	Then 'Quarta'
							when js.freq_interval = 4	Then 'Ter�a'
							when js.freq_interval = 2	Then 'Segunda'
							when js.freq_interval = 1	Then 'Domingo'
							else 'Schedulle diferenciado'
							end
			  when freq_type = 16 then 'Todo dia ' + cast(js.freq_interval as varchar) + ' de cada mes'
		end [Execu��o],
		case  	when js.freq_subday_type = 0 then 'Ativado Manualmente'
			  	when js.freq_subday_type > 1 then 'A cada ' + cast(js.freq_subday_interval as varchar) + 
			  		case	when js.freq_subday_type = 2 then ' segundo(s)'
						when js.freq_subday_type = 4 then ' minuto(s)'
						when js.freq_subday_type = 8 then ' hora(s)'
				  	end
		else
		substring(right('000000'+convert(varchar, js.active_start_time),6), 1, 2)+ ':' + substring(right('000000'+convert(varchar, js.active_start_time),6),3,2)
		end [Freq��ncia/Hor�rio],
		case when js.next_run_time <> 0 then 
		substring(convert(varchar, js.next_run_date), 7, 2)+ '/' + substring(convert(varchar, js.next_run_date),5,2) + '/' + convert(varchar, left(js.next_run_date , 4)) + ' ' +
		substring(right('000000'+convert(varchar, js.next_run_time),6), 1, 2)+ ':' + substring(right('000000'+convert(varchar, js.next_run_time),6),3,2)
		else 'NA' 
		end [Pr�xima Execu��o],
		case when jt.last_run_date = 0 then 'sem hist�rico'
		else 	right(cast(jt.last_run_date as varchar), 2) + '/' +
			substring(cast(jt.last_run_date as varchar), 5, 2) + '/' +
			left(cast(jt.last_run_date as varchar), 4) + ' ' +
            		left(right('0' + cast(jt.last_run_time as varchar), 6), 2) + ':' + 
            		substring(right('0' + cast(jt.last_run_time as varchar), 6), 3, 2) + ':' + 
            		right(cast(jt.last_run_time as varchar), 2)
		end [�ltima Execu��o],
		case when jt.last_run_date = 0 then 'sem hist�rico'
		else reverse(STUFF(STUFF(reverse(case when len(cast(jt.last_run_duration as varchar)) < 6 then right('00000'+cast(jt.last_run_duration as varchar), 6) else cast(jt.last_run_duration as varchar) end), 3, 0, ':'), 6, 0, ':'))
		end [Tempo �ltima Execu��o],
		case when jt.last_run_outcome = 1 then 'OK'
			 when jt.last_run_outcome = '' and jt.last_run_date = 0 then 'Sem hist�rico'
		else 'ERROR !!!' end [Status],
		case when jt.last_run_date = 0 then 'sem hist�rico'
		else Substring(jh.message,1,233)
		end MENSAGEM
from msdb..sysjobs j
inner join msdb..sysjobsteps jt on j.job_id = jt.job_id
left  join msdb..sysjobschedules js on j.job_id = js.job_id
left  join msdb..sysjobhistory jh on jh.job_id = j.job_id and jh.step_id = jt.step_id and jh.run_date = jt.last_run_date and jh.run_time = jt.last_run_time
order by j.name

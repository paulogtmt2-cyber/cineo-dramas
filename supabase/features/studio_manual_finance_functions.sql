create function public.cineo_review_month(actor uuid,owner uuid,period date,approved bigint,note text) returns jsonb language plpgsql security invoker set search_path='' as $$declare n bigint;gross bigint;result_id uuid;begin
 if not exists(select 1 from public.cineo_admins where user_id=actor) then raise exception 'Acesso restrito';end if;
 perform 1 from public.cineo_creator_accounts where user_id=owner for update;if not found then raise exception 'Cadastro de criador inexistente';end if;
 if period<>date_trunc('month',period)::date or period>=date_trunc('month',now() at time zone 'America/Sao_Paulo')::date or length(trim(note))<5 then raise exception 'Revise um mês encerrado e informe o parecer';end if;
 if exists(select 1 from public.cineo_copyright_cases where creator_id=owner and status='reviewing') then raise exception 'Há uma investigação de direitos em andamento';end if;
 select count(*),floor(coalesce(sum(rate_cents_per_thousand),0)/1000.0) into n,gross from public.cineo_qualified_views where creator_id=owner and day>=period and day<(period+interval '1 month')::date;
 if approved<0 or approved>gross then raise exception 'O valor aprovado excede a estimativa do mês';end if;
 insert into public.cineo_monthly_settlements(creator_id,month,views,gross_cents,approved_cents,reason,reviewed_by) values(owner,period,n,gross,approved,left(note,2000),actor) returning id into result_id;
 insert into public.cineo_studio_audit(creator_id,actor_id,action,detail) values(owner,actor,'month_closed',jsonb_build_object('id',result_id,'month',period,'gross_cents',gross,'approved_cents',approved,'reason',left(note,2000)));
 return jsonb_build_object('id',result_id,'gross_cents',gross,'approved_cents',approved);
end$$;
create function public.cineo_request_withdrawal(actor uuid,amount bigint,envelope jsonb,hint text,terms integer) returns jsonb language plpgsql security invoker set search_path='' as $$declare rules public.cineo_payout_rules;available bigint;out_id uuid;begin
 perform 1 from public.cineo_creator_accounts where user_id=actor and status='approved' for update;if not found then raise exception 'Cadastro de criador não está ativo';end if;
 select * into rules from public.cineo_payout_rules where id=1;
 if not rules.enabled or rules.minimum_cents is null or length(rules.terms)<10 then raise exception 'Saques ainda não habilitados pelo administrador';end if;
 if terms<>rules.revision then raise exception 'As regras mudaram. Leia e aceite novamente';end if;
 select coalesce((select sum(approved_cents) from public.cineo_monthly_settlements where creator_id=actor),0)-coalesce((select sum(amount_cents) from public.cineo_withdrawals where creator_id=actor and status in('requested','approved','paid')),0) into available;
 if amount<rules.minimum_cents or amount>available then raise exception 'Valor fora do mínimo ou do saldo revisado disponível';end if;
 if not (envelope ? 'ciphertext' and envelope ? 'iv') or length(hint)>100 then raise exception 'Destino de pagamento inválido';end if;
 insert into public.cineo_withdrawals(creator_id,amount_cents,pix_envelope,pix_hint,terms_revision) values(actor,amount,envelope,hint,terms) returning id into out_id;
 insert into public.cineo_studio_audit(creator_id,actor_id,action,detail) values(actor,actor,'withdrawal_requested',jsonb_build_object('id',out_id,'amount_cents',amount));return jsonb_build_object('id',out_id);
end$$;
create function public.cineo_review_withdrawal(actor uuid,target uuid,decision text,note text,reference text default '') returns jsonb language plpgsql security invoker set search_path='' as $$declare r public.cineo_withdrawals;begin
 select * into r from public.cineo_withdrawals where id=target for update;if not found then raise exception 'Solicitação inexistente';end if;
 if decision='cancelled' then if actor<>r.creator_id or r.status<>'requested' then raise exception 'Cancelamento não permitido';end if;
 else
 if not exists(select 1 from public.cineo_admins where user_id=actor) then raise exception 'Acesso restrito';end if;
 if decision not in('approved','rejected','paid') or (decision='paid' and r.status<>'approved') or (decision<>'paid' and r.status<>'requested') then raise exception 'Transição de pagamento inválida';end if;
 if decision='paid' and (length(trim(reference))<6 or length(trim(note))<5) then raise exception 'Registre a referência e o comprovante do pagamento externo';end if;
 if decision='rejected' and length(trim(note))<5 then raise exception 'Informe o motivo da recusa';end if;
 if decision in('approved','paid') and not exists(select 1 from public.cineo_creator_accounts where user_id=r.creator_id and status='approved') then raise exception 'Criador suspenso ou inativo';end if;
 end if;
 update public.cineo_withdrawals set status=decision,note=left(note,2000),payment_reference=case when decision='paid' then trim(reference) else payment_reference end,updated_at=now() where id=target;
 insert into public.cineo_studio_audit(creator_id,actor_id,action,detail) values(r.creator_id,actor,'withdrawal_'||decision,jsonb_build_object('id',target,'amount_cents',r.amount_cents,'note',left(note,2000),'reference',case when decision='paid' then trim(reference) else '' end));return jsonb_build_object('ok',true);
end$$;
create function public.cineo_studio_finance(owner uuid) returns jsonb language sql stable security invoker set search_path='' as $$select jsonb_build_object('rules',(select to_jsonb(r) from public.cineo_payout_rules r where id=1),'available_cents',coalesce((select sum(approved_cents) from public.cineo_monthly_settlements where creator_id=owner),0)-coalesce((select sum(amount_cents) from public.cineo_withdrawals where creator_id=owner and status in('requested','approved','paid')),0),'months',(select coalesce(jsonb_agg(x order by month desc),'[]') from(select date_trunc('month',day)::date as month,count(*) views,floor(sum(rate_cents_per_thousand)/1000.0) gross_cents from public.cineo_qualified_views where creator_id=owner group by 1)x),'settlements',(select coalesce(jsonb_agg(s order by month desc),'[]') from public.cineo_monthly_settlements s where creator_id=owner),'withdrawals',(select coalesce(jsonb_agg(x order by created_at desc),'[]') from(select id,amount_cents,pix_hint,status,note,payment_reference,created_at from public.cineo_withdrawals where creator_id=owner order by created_at desc limit 100)x))$$;

do $$declare p record;begin for p in select oid::regprocedure signature from pg_proc where pronamespace='public'::regnamespace and proname in('cineo_follower_event','cineo_studio_role','cineo_studio_delegate','cineo_studio_new_show','cineo_studio_report','cineo_episode_retention','cineo_review_month','cineo_request_withdrawal','cineo_review_withdrawal','cineo_studio_finance') loop execute format('revoke all on function %s from public,anon,authenticated',p.signature);execute format('grant execute on function %s to service_role',p.signature);end loop;end$$;


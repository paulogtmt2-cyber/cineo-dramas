create or replace function public.cineo_review_withdrawal(actor uuid,target uuid,decision text,note text,reference text default '') returns jsonb language plpgsql security invoker set search_path='' as $$declare r public.cineo_withdrawals;begin
 select * into r from public.cineo_withdrawals where id=target for update;if not found then raise exception 'Solicitação inexistente';end if;
 if decision='cancelled' then if actor<>r.creator_id or r.status<>'requested' then raise exception 'Cancelamento não permitido';end if;
 else
 if not exists(select 1 from public.cineo_admins where user_id=actor) then raise exception 'Acesso restrito';end if;
 if decision not in('approved','rejected','paid') or (decision='paid' and r.status<>'approved') or (decision<>'paid' and r.status<>'requested') then raise exception 'Transição de pagamento inválida';end if;
 if decision='paid' and (length(trim(reference))<6 or length(trim(note))<5) then raise exception 'Registre a referência e o comprovante do pagamento externo';end if;
 if decision='rejected' and length(trim(note))<5 then raise exception 'Informe o motivo da recusa';end if;
 if decision in('approved','paid') and not exists(select 1 from public.cineo_creator_accounts where user_id=r.creator_id and status='approved') then raise exception 'Criador suspenso ou inativo';end if;
 end if;
 update public.cineo_withdrawals set status=decision,note=left(cineo_review_withdrawal.note,2000),payment_reference=case when decision='paid' then trim(reference) else payment_reference end,updated_at=now() where id=target;
 insert into public.cineo_studio_audit(creator_id,actor_id,action,detail) values(r.creator_id,actor,'withdrawal_'||decision,jsonb_build_object('id',target,'amount_cents',r.amount_cents,'note',left(note,2000),'reference',case when decision='paid' then trim(reference) else '' end));return jsonb_build_object('ok',true);
end$$;

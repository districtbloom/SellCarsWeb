-- H05 state machine. All purchases, quotes and job completion run on the server.
local D=require(script.Parent.HubData)
local M={}
function M.copy(t)if type(t)~='table'then return t end;local n={};for k,v in t do n[k]=M.copy(v)end;return n end
function M.fresh()return {cash=7000,pads={},sales=0,clock=0,history={},ledger={},worker={hired=false,level=1,jobs=0,pos=M.copy(D.points.mechanic),activity='Ready'},seen=false,lowballPassed=false,completed=false}end
function M.has(s,id)return table.find(s.pads,id)~=nil end
function M.def(s)return s.car and D.cars[s.car.index]end
function M.note(s,text)s.notice=text;s.noticeUntil=s.clock+3 end
function M.pay(s,n,kind,subject)if type(n)~='number'or n~=n or n<0 or s.cash<n then return false end;s.cash-=n;table.insert(s.ledger,{amount=-n,kind=kind,subject=subject});return true end
function M.event(s,text)if s.car then table.insert(s.car.history,text)end end
function M.terms(s)local d=M.def(s);local discount=s.car.remote and 300 or 0;return {ask=d.ask-discount,floor=d.floor-discount}end
function M.reserve(s)
 if s.personal and s.personal.route and s.personal.route.target=='lead'then return 5700 end
 local c=s.car;if not c then return s.lead and s.lead.kind=='rare'and 6000 or 0 end
 if c.index==4 and not c.owned then return (c.quote and c.quote.accepted or M.terms(s).ask)+D.quote(M.def(s)).cost end
 if c.owned and not c.plan then return D.quote(M.def(s)).cost end
 if c.plan and c.plan.funded then return 0 end
 local sum=0;if c.plan then for _,j in c.plan.jobs do if not j.started then sum+=j.cost end end end;return sum
end
function M.eligible(s,p)
 if M.has(s,p.id)or s.sales<p.at or (p.ownedCar and not(s.car and s.car.owned))or(p.readyCar and not(s.car and s.car.status=='ready'))then return false end
 for _,id in p.after do if not M.has(s,id)then return false end end;return true
end
function M.nextPad(s)for _,p in D.pads do if not p.optional and M.eligible(s,p)then return p end end end
function M.lead(s,status)s.lead={kind='rare',index=4,status=status or 'ringing',caller='Jo',text='Elias has a rare Phoenix. Meet him, or ask him to bring it here.'}end
function M.buyPad(s,id)
 local p;for _,row in D.pads do if row.id==id then p=row end end
 if not p or not M.eligible(s,p)then return false end
 if s.cash-M.reserve(s)<p.cost then M.note(s,'Need $'..math.ceil(p.cost-math.max(0,s.cash-M.reserve(s)))..' more. Work money stays safe.');return false end
 M.pay(s,p.cost,'pad',p.name);table.insert(s.pads,id);M.note(s,p.name..' ready')
 if id=='intake'then M.arrive(s,1)end
 if id=='air'and s.car and s.car.owned then M.plan(s,'Quick');M.note(s,'Bay ready. $'..s.car.plan.cost..' work funded.')end
 if id=='salesdesk'and s.car and s.car.status=='ready'then M.route(s,'sales')end
 if id=='finish'then s.lead={kind='ordinary',index=2,status='ringing',caller='Maya',text='I’ve got a coupe you might like. Can I bring it by?'}end
 if id=='mechanic'then s.worker.hired=true;s.lead={kind='ordinary',index=3,status='ringing',caller='Nora',text='A small hatchback. Your mechanic could give it a new start.'}end
 if id=='display'then s.personal={id='your-coupe',pos=M.copy(D.points.garage),home=M.copy(D.points.garage),status='parked'};s.rareCallAt=s.clock+3;M.note(s,'Your own car. You’ve earned this.')end
 return true
end
function M.arrive(s,index,remote)
 if s.car or(not remote and s.personal and s.personal.status~='parked')then return false end
 local d=D.cars[index];if not d then return false end
 if index==4 and s.cash<d.ask-(remote and 300 or 0)+D.quote(d).cost then M.note(s,'Build cash with another ordinary flip first.');return false end
 s.car={id=d.id..'-'..(s.sales+1),index=index,owned=false,status='arriving',pos=M.copy(D.points.entry),condition=M.copy(d.condition),arrivalGrade=D.grade(d.condition),depth='Quick',workSpent=0,purchase=0,history={},remote=remote==true,buyerAttempt=0,photo=false}
 s.car.route={target='intake',points={M.copy(D.points.entry),{-16,-12},{D.points.intake[1],-12},M.copy(D.points.intake)},step=2}
 if remote then s.car.pos={40,-45};s.car.route=nil;s.car.status=s.seen and 'seller'or'discovery'end
 M.event(s,remote and 'Found at Elias’s garage'or'Arrived at the dealership');s.lead=nil;return true
end
function M.buy(s)
 local c=s.car;if not c or c.status~='seller'or c.owned or not c.quote or c.quote.mode~='buy'then return false end
 local amount=c.quote.accepted;local setup=0;for _,id in {'repairbay','tools','power','air','sales','salesdesk'}do if not M.has(s,id)then for _,p in D.pads do if p.id==id then setup+=p.cost end end end end
 if s.cash<amount+D.quote(M.def(s)).cost+setup then M.note(s,'Keep enough for repairs and the sale corner.');return false end
 M.pay(s,amount,'car',M.def(s).name);c.purchase=amount;c.owned=true;c.quote=nil;c.status=M.has(s,'air')and'choose'or'owned';M.event(s,'Bought for $'..amount)
 if c.remote then c.status='moving';c.route={target='intake',points={M.copy(c.pos),{40,-36},{26,-36},{26,-12},{D.points.intake[1],-12},M.copy(D.points.intake)},step=2};M.returnHome(s);M.note(s,'Elias brings the Phoenix. Drive your car home.')end;return true
end
function M.route(s,target)local c=s.car;local p=c.pos;c.status='moving';c.route={target=target,points={M.copy(p),{p[1],-12},{D.points[target][1],-12},M.copy(D.points[target])},step=2}end
function M.plan(s,depth)
 local c=s.car;if not c or not c.owned or c.plan or(c.status~='choose'and c.status~='owned')or(depth~='Quick'and depth~='Good')or(depth=='Good'and not M.has(s,'finish'))then return false end
 local q=D.quote(M.def(s),depth);if s.cash<q.cost then M.note(s,'Need $'..math.ceil(q.cost-s.cash)..' more for this work.');return false end
 M.pay(s,q.cost,'work',M.def(s).name..' work plan');q.funded=true;c.workSpent+=q.cost;c.plan=q;c.depth=depth;M.event(s,'Chose '..depth);M.route(s,'repair');return true
end
function M.job(s)if s.car and s.car.plan then for _,j in s.car.plan.jobs do if not j.done then return j end end end end
function M.startJob(s)
 local c=s.car;local j=M.job(s);if not c or c.status~='repair'or not j or j.started or(s.worker.hired and s.worker.activity~='Working')then return false end
 if not c.plan.funded then if not M.pay(s,j.cost,'work',j.name)then return false end;c.workSpent+=j.cost end;j.started=true;j.speed=s.worker.hired and s.worker.level>1 and 1.25 or 1;return true
end
function M.list(s)local c=s.car;if not c or c.status~='photo'then return false end;c.photo=true;c.listing=true;c.status='buyer';M.event(s,'Photographed and listed');M.note(s,'Photo taken. Your listing is live.');return true end
function M.fit(c,role)
 local custom=c.custom or{paint='original',wheels='original',stripe=false}
 if role=='Collector'then local original=custom.paint=='original'and custom.wheels=='original'and not custom.stripe;return original and 300 or -150,original and 'Original character'or'Prefers original',original and 'That original shape. That’s what I came for.'or'I’d have kept the original look.'end
 if role=='Enthusiast'then return(custom.paint~='original'and 80 or 0)+(custom.wheels=='sport'and 180 or 0)+(custom.stripe and 100 or 0),'Style matters',custom.wheels=='sport'and'Those sport wheels suit it. My kind of coupe.'or'A clean coupe. I can make it my own.'end
 return 0,'Repairs matter','The repair work is done. That’s what matters to me.'
end
function M.buyer(s)
 local c=s.car;local d=M.def(s);local base=d.offers[c.depth=='Good'and 2 or 1]
 if c.index==2 and not s.lowballPassed then local cost=c.purchase+c.plan.cost;return {name='Blake',role='Bargain hunter',line='I’m buying a deal. Extras don’t change my budget.',cue='Price first',ask=cost-150,max=cost-50,lowball=true}end
 local role=c.index==2 and'Enthusiast'or d.buyerRole;local bonus,cue,line=M.fit(c,role)
 return {name=c.index==2 and'Riley'or d.buyer,role=role,line=line,cue=cue,ask=base+bonus,max=base+bonus+(c.index==1 and 100 or(d.buyerMax~=0 and d.buyerMax or 100))}
end

function M.estimate(s,depth,choice)
 local c=s.car;local d=M.def(s);if not c then return nil end
 local role=c.index==2 and 'Enthusiast'or d.buyerRole
 local candidate=M.copy(c);if choice then candidate.custom=choice end
 local bonus=M.fit(candidate,role)
 local quote=D.quote(d,depth or c.depth)
 local sale=d.offers[(depth or c.depth)=='Good'and 2 or 1]+bonus
 return {sale=sale,profit=sale-c.purchase-quote.cost,role=role,seconds=quote.seconds,cost=quote.cost}
end
function M.leadBudget(s,visit)
 local needed=(visit and 4500 or 4800)+D.quote(D.cars[4]).cost
 return needed,math.max(0,needed-s.cash)
end

function M.openDeal(s)
 local c=s.car;if not c or(c.status~='seller'and c.status~='buyer')then return false end
 local mode=c.status=='seller'and'buy'or'sell';if not c.quote then local b=mode=='sell'and M.buyer(s);local price=b and b.ask or M.terms(s).ask;c.quote={mode=mode,accepted=price,line=b and b.line or M.def(s).sellerLine,reaction='neutral',revision=0}end;return true
end
function M.counter(s,amount)
 local c=s.car;local q=c and c.quote;if not q or type(amount)~='number'or amount~=amount or amount<50 or amount>20000 or amount%50~=0 then return false end
 if q.mode=='buy'then local t=M.terms(s);if amount>t.ask then return false end;q.accepted=math.max(amount,t.floor);q.reaction=amount>=t.floor and'happy'or'firm';q.line=amount>=t.floor and'You’ve got a deal.'or('I can do $'..t.floor..'. That’s my price.')
 else local b=M.buyer(s);if amount<q.accepted then return false end;if amount<=b.max then q.accepted=amount;q.reaction='happy';q.line='All right. Let’s do it.'else q.reaction='firm';q.line='It’s a nice car, but that’s too much for me.'end end;q.revision=(q.revision or 0)+1;return true
end
function M.decline(s)if not s.car or s.car.status~='buyer'then return false end;s.lowballPassed=true;s.car.quote=nil;s.car.status='waitingBuyer';s.car.wait=4;M.note(s,'Listing stays live. Another buyer is coming.');return true end
function M.sell(s)
 local c=s.car;if not c or c.status~='buyer'or not c.quote or c.quote.mode~='sell'then return false end
 c.sale=c.quote.accepted;c.soldTo=M.buyer(s);s.cash+=c.sale;table.insert(s.ledger,{amount=c.sale,kind='sale',subject=M.def(s).name});c.quote=nil;c.status='sold';c.receiptUntil=s.clock+2;M.event(s,'Sold to '..c.soldTo.name);return true
end
function M.customize(s,choice)
 local c=s.car;if not c or c.status~='photo'or not M.has(s,'finish')or type(choice)~='table'then return false end
 if not table.find({'original','cream','blue','red','green'},choice.paint)or not table.find({'original','sport'},choice.wheels)or type(choice.stripe)~='boolean'then return false end
 local old=c.custom or{paint='original',wheels='original',stripe=false};local cost=(old.paint~=choice.paint and 180 or 0)+(old.wheels~=choice.wheels and 120 or 0)+(old.stripe~=choice.stripe and 80 or 0)
 if cost==0 then return true end;if not M.pay(s,cost,'customization',M.def(s).name)then return false end;c.workSpent+=cost;c.custom=M.copy(choice);c.photo=false;return true
end
function M.upgrade(s)if not s.worker.hired or s.worker.level~=1 or s.worker.jobs<1 or s.cash-M.reserve(s)<350 then return false end;M.pay(s,350,'staff','Jo training');s.worker.level=2;M.note(s,'Jo trained. Next repairs take 20% less time.');return true end
function M.visit(s)
 if not s.personal or s.personal.status~='parked'or s.car or not s.lead or s.lead.kind~='rare'then return false end
 if s.cash<5700 then M.note(s,'Keep $5,700 for the Phoenix and repairs.');return false end
 local p=s.personal;p.route={target='lead',points={M.copy(p.pos),{p.pos[1],-26},{55,-26},{55,-36},{46,-36},{46,-42}},step=2};p.status='driving';s.lead.status='visiting';return true
end
function M.returnHome(s)local p=s.personal;if not p or p.status~='atLead'then return false end;p.route={target='home',points={M.copy(p.pos),{46,-36},{55,-36},{55,-26},{p.home[1],-26},M.copy(p.home)},step=2};p.status='driving';return true end
function M.leave(s)if not s.personal or s.personal.status~='atLead'or(s.car and s.car.owned)then return false end;s.car=nil;M.lead(s,'missed');return M.returnHome(s)end
function M.discover(s)if s.car and s.car.status=='discovery'then s.seen=true;s.car.status='seller' end end
local function move(o,dt,speed)
 local r=o.route;if not r then return end;local p=r.points[r.step];local dx,dz=p[1]-o.pos[1],p[2]-o.pos[2];local dist=math.sqrt(dx*dx+dz*dz);if dist>.001 then o.angle=math.atan2(-dx,dz)end
 if dist<=dt*speed then o.pos=M.copy(p);r.step+=1;if r.step>#r.points then o.route=nil;return r.target end
 elseif dt>0 then o.pos[1]+=dx/dist*dt*speed;o.pos[2]+=dz/dist*dt*speed end
end
function M.tick(s,dt,throttle)
 s.clock+=dt;if s.rareCallAt and s.clock>=s.rareCallAt then s.rareCallAt=nil;M.lead(s)end
 if s.personal and s.personal.route then local goal=move(s.personal,dt*(throttle or 0),9);if goal then s.personal.status=goal=='lead'and'atLead'or'parked';if goal=='lead'then M.arrive(s,4,true)else M.note(s,'Home. Your dealership is ready.')end end end
 local c=s.car;local w=s.worker
 if w.hired then local j=c and c.status=='repair'and M.job(s);local o=j and({Body={-2,0},RunningGear={-2,1},Mechanical={0,3},Exterior={2,0},Tune={0,3}})[j.id];local goal=o and{c.pos[1]+o[1],c.pos[2]+o[2]}or D.points.mechanic
  if not w.goal or w.goal[1]~=goal[1]or w.goal[2]~=goal[2]then w.goal=M.copy(goal);local front=c and c.pos[2]+3.6 or goal[2];w.route={target='work',step=2,points={M.copy(w.pos),{w.pos[1],front},{goal[1],front},M.copy(goal)}}end
  if w.route then move(w,dt,4);w.activity=j and'Heading to '..j.name or'Returning'else w.activity=j and'Working'or'Ready'end
 end
 if not c then return end
 if c.route then local dest=move(c,dt,7);if dest=='intake'then if c.owned then c.remote=false;c.status='choose'else c.status=c.index==4 and not s.seen and'discovery'or'seller'end
 elseif dest=='repair'then c.status='repair'
 elseif dest=='sales'then c.status=c.index==1 and'buyer'or'photo';c.listing=c.index==1
 elseif dest=='exit'then table.insert(s.history,M.copy(c));s.car=nil;s.sales+=1;if c.index==4 then s.completed=true elseif s.sales>=3 and s.personal then M.lead(s,'missed')end end;return end
 if c.status=='repair'then local j=M.job(s);if j then if w.hired and not j.started and w.activity=='Working'then M.startJob(s)end;if j.started then j.progress=math.min(1,j.progress+dt*j.speed/j.seconds);if j.progress>=1 then j.done=true;if c.condition[j.id]then c.condition[j.id]='Good'end;M.event(s,j.name..' completed')end end end
  if not M.job(s)then c.status='ready';if w.hired then w.jobs+=1 end;if M.has(s,'salesdesk')then M.route(s,'sales')end end
 elseif c.status=='waitingBuyer'then c.wait-=dt;if c.wait<=0 then c.status='buyer'end
 elseif c.status=='sold'and s.clock>=c.receiptUntil then M.route(s,'exit')end
end
return M


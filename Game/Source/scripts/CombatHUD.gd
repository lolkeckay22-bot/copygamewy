extends Reference
func draw(h):
	var game=h.game;var a=game.player;var combat=game.combat
	if a==null:return
	var center=Vector2(115,185);var radius=76.0
	h.panel(Rect2(28,92,180,205),Color(.025,.045,.06,.8))
	h.txt(Vector2(42,111),"РАДАР / 4 КМ",12,h.muted)
	h.draw_arc(center,radius,0,TAU,48,h.muted,1,true)
	h.draw_arc(center,radius*.5,0,TAU,32,Color(.2,.3,.33),1,true)
	h.draw_line(center-Vector2(radius,0),center+Vector2(radius,0),Color(.2,.3,.33),1)
	h.draw_line(center-Vector2(0,radius),center+Vector2(0,radius),Color(.2,.3,.33),1)
	h.txt(center+Vector2(-4,-radius-4),"С",12,h.ink)
	for unit in game.aircraft+game.ground_units:
		if unit==a or unit.dead:continue
		var delta=unit.translation-a.translation;var offset=Vector2(delta.x,delta.z)/4000*radius
		if offset.length()>radius:continue
		var color=h.cyan if unit.team==a.team else Color(1,.4,.3)
		if game.ground_units.has(unit):h.draw_rect(Rect2(center+offset-Vector2(2,2),Vector2(4,4)),color)
		else:h.draw_circle(center+offset,2.5,color)
		if unit==combat.selected_target:h.draw_arc(center+offset,6,0,TAU,16,h.amber,1,true)
	var f=-a.global_transform.basis.z;var direction=Vector2(f.x,f.z).normalized()
	h.draw_line(center,center+direction*15,h.ink,2,true);h.draw_circle(center,3,h.ink)
	var home=combat.home(a);var diff=home-a.translation;var home_offset=Vector2(diff.x,diff.z)/4000*radius
	if home_offset.length()>radius:home_offset=home_offset.normalized()*radius
	h.draw_arc(center+home_offset,5,0,TAU,16,h.cyan,2,true)
	h.txt(Vector2(41,283),"БАЗА %.1f КМ"%(Vector2(diff.x,diff.z).length()/1000),12,h.cyan)
	var stat=combat.stats(a)
	h.txt(Vector2(30,324),"СБИТО %d НАЗЕМНЫХ %d ПОМОЩЬ %d"%[stat.kills,stat.ground,stat.assists],12,h.ink)
	var y=310
	for event in combat.feed:
		if combat.clock-event.time>8:continue
		h.txt(Vector2(971,y),event.text,12,h.cyan if event.team==0 else h.amber);y+=22
	var target=combat.selected_target
	if combat.valid(target):
		var distance=a.translation.distance_to(target.translation)
		var hp=target.hp/target.data.hp if game.ground_units.has(target) or game.service_bases.targets.has(target) else target.damage.health
		h.panel(Rect2(432,570,420,70))
		h.txt(Vector2(449,594),"ЦЕЛЬ: "+target.data.name,14,h.amber)
		h.txt(Vector2(449,620),"%.2f КМ   СОСТОЯНИЕ %d%%   T: ВОЗДУХ / H: ЗЕМЛЯ"%[distance/1000,int(hp*100)],12,h.ink)
		var target_pos=target.aim_point() if target.has_method("aim_point") else target.translation
		var p=h.screen_point(target_pos)
		if game.camera.is_position_behind(target_pos) or p.x<40 or p.x>1240 or p.y<115 or p.y>550:
			var relative=game.camera.global_transform.basis.xform_inv(target_pos-game.camera.translation)
			var toward=Vector2(relative.x,-relative.y).normalized()
			if toward.length_squared()<.01:toward=Vector2.DOWN
			p=Vector2(640,360)+toward*250
			var side=Vector2(-toward.y,toward.x)
			h.draw_colored_polygon(PoolVector2Array([p+toward*12,p-toward*6+side*6,p-toward*6-side*6]),h.amber)
		else:h.draw_arc(p,17,0,TAU,32,h.amber,2,true)
	if not game.camera.is_position_behind(home):
		var base_pos=h.screen_point(home)
		if base_pos.x>220 and base_pos.x<960 and base_pos.y>140 and base_pos.y<550:
			h.draw_arc(base_pos,12,0,TAU,24,h.cyan,1,true)
			h.txt(base_pos+Vector2(17,4),"ЗОНА ОБСЛУЖИВАНИЯ",12,h.cyan)
	var progress=combat.service_status(a)
	if progress>0:
		h.panel(Rect2(414,190,450,65));h.txt(Vector2(432,215),"ОБСЛУЖИВАНИЕ %d%% — СТОЙТЕ, ТЯГА 0"%int(progress/5*100),14,h.cyan)
		h.draw_rect(Rect2(432,233,410*min(1,progress/5),5),h.cyan)
	elif Vector2(diff.x,diff.z).length()<1500 and not a.dead:
		h.txt(Vector2(392,219),"СЯДЬТЕ И ОСТАНОВИТЕСЬ НА СВОЕЙ ВПП — РЕМОНТ 5 С",14,h.cyan)
	h.txt(Vector2(30,350),"G ШАССИ: "+("ВЫПУЩЕНЫ" if a.landing.gear_down else "УБРАНЫ")+"   B ТОРМОЗ",12,h.cyan)
	h.txt(Vector2(30,375),"НАБОР %.1f М/С   НАД ЗЕМЛЁЙ %d М"%[a.linear_velocity.y,int(a.translation.y-game.terrain.height_at(a.translation.x,a.translation.z))],12,h.muted)
	h.txt(Vector2(30,400),"Z ЗАКРЫЛКИ: "+["УБРАНЫ","ВЗЛЁТ","ПОСАДКА"][a.flight_controls.flaps],12,h.cyan)
	h.txt(Vector2(30,425),"ПКМ ПРИБЛИЖЕНИЕ   ALT ВИД НА ЦЕЛЬ",12,h.muted)
	if a.landing.grounded:h.txt(Vector2(500,465),"НА ВПП — УВЕЛИЧЬТЕ ТЯГУ ДЛЯ ВЗЛЁТА",14,h.cyan)

	if a.spawn_protection>0 and not a.dead:h.txt(Vector2(470,185),"ЗАЩИТА %.1f С — ОГОНЬ ОТМЕНЯЕТ"%a.spawn_protection,14,h.cyan)
	h.draw_rect(Rect2(44,651,200,4),Color(.18,.24,.26))
	h.draw_rect(Rect2(44,651,200*a.weapons.heat,4),h.amber if a.weapons.heat>.7 else h.cyan)
	if a.weapons.overheated:h.txt(Vector2(488,440),"ПУШКА ПЕРЕГРЕТА",16,h.amber)
	if game.mode=="results":return
	if game.match_state.elapsed<15 and not a.dead:
		h.txt(Vector2(387,665),"T: ВОЗДУХ   H: ЗЕМЛЯ / АЭРОДРОМ   V: РАКЕТА   J: ДЫМ",12,h.ink)

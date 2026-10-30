/// Lightweight, dev-only telemetry for the Phase 6 wave-40 performance gate.
/// The caller supplies the live run values so this probe has no hidden
/// dependency on the level controller or its static inventory.
function scr_perf_watch_snapshot() {
	var _snapshot = {alive:0, statused:0, effects:0};
	global.perf_watch_snapshot = _snapshot;

	with(obj_mon){
		var _is_dying = variable_instance_exists(id, "dying") && dying;
		if(!_is_dying){
			global.perf_watch_snapshot.alive += 1;
			if(variable_instance_exists(id, "status_count")
			&& is_real(status_count) && status_count > 0){
				global.perf_watch_snapshot.statused += 1;
				global.perf_watch_snapshot.effects += status_count;
			}
		}
	}

	global.perf_watch_snapshot = undefined;
	return _snapshot;
}

/// Probe only after wave 40, and log five-second windows only while at least
/// 60 monsters are alive. The global.devMode guard at the call site keeps
/// this diagnostic out of normal runs.
function scr_perf_watch_step(_watch, _wave, _delta_us, _target_fps) {
	if(!variable_global_exists("devMode") || !global.devMode) return;
	if(!is_struct(_watch) || !is_real(_wave) || _wave < 40) return;
	if(!is_real(_delta_us) || _delta_us <= 0) return;
	if(!variable_struct_exists(_watch, "active")
	|| !variable_struct_exists(_watch, "probe_us")
	|| !variable_struct_exists(_watch, "wait_us")
	|| !variable_struct_exists(_watch, "sample_us")
	|| !variable_struct_exists(_watch, "steps")
	|| !variable_struct_exists(_watch, "worst_us")
	|| !variable_struct_exists(_watch, "missed")) return;
	if((_watch.active != true && _watch.active != false)
	|| !is_real(_watch.probe_us) || !is_real(_watch.wait_us)
	|| !is_real(_watch.sample_us) || !is_real(_watch.steps)
	|| !is_real(_watch.worst_us) || !is_real(_watch.missed)) return;

	var _target = (is_real(_target_fps) && _target_fps > 0)
		? _target_fps : 60;

	if(!_watch.active){
		_watch.probe_us += _delta_us;
		if(_watch.probe_us < 1000000) return;
		_watch.probe_us = 0;

		var _population = scr_perf_watch_snapshot();
		if(!is_struct(_population)
		|| !variable_struct_exists(_population, "alive")
		|| !variable_struct_exists(_population, "statused")
		|| !variable_struct_exists(_population, "effects")) return;

		if(_population.alive < 60){
			_watch.wait_us += _delta_us;
			if(_watch.wait_us >= 5000000){
				_watch.wait_us = 0;
				print("PERF  W40+ waiting wave=", _wave,
				      " alive=", _population.alive, " target_alive=60");
			}
			return;
		}

		_watch.active = true;
		_watch.wait_us = 0;
		_watch.sample_us = 0;
		_watch.steps = 0;
		_watch.worst_us = 0;
		_watch.missed = 0;
		print("PERF  W40+ start wave=", _wave,
		      " target_fps=", _target, " alive=", _population.alive);
		return;
	}

	_watch.sample_us += _delta_us;
	_watch.steps += 1;
	_watch.worst_us = max(_watch.worst_us, _delta_us);
	/// Ignore microsecond rounding and minor scheduler jitter; count frames
	/// that miss their budget by more than five percent.
	if(_delta_us > 1.05 * (1000000 / _target)) _watch.missed += 1;
	if(_watch.sample_us < 5000000) return;

	var _sample = scr_perf_watch_snapshot();
	if(!is_struct(_sample)
	|| !variable_struct_exists(_sample, "alive")
	|| !variable_struct_exists(_sample, "statused")
	|| !variable_struct_exists(_sample, "effects")) return;

	if(_sample.alive < 60){
		print("PERF  W40+ sample skipped wave=", _wave,
		      " alive=", _sample.alive, " target_alive=60");
		_watch.active = false;
		_watch.probe_us = 0;
		_watch.wait_us = 0;
		_watch.sample_us = 0;
		_watch.steps = 0;
		_watch.worst_us = 0;
		_watch.missed = 0;
		return;
	}

	var _avg_fps = _watch.steps / max(_watch.sample_us / 1000000, 0.001),
	    _worst_ms = _watch.worst_us / 1000,
	    _missed_pct = 100 * _watch.missed / max(_watch.steps, 1);
	print("PERF  W40+ wave=", _wave,
	      " target_fps=", _target,
	      " avg_fps=", round(_avg_fps * 10) / 10,
	      " worst_ms=", round(_worst_ms * 10) / 10,
	      " slow5pct=", round(_missed_pct * 10) / 10, "%",
	      " alive=", _sample.alive,
	      " statused=", _sample.statused,
	      " effects=", _sample.effects);

	_watch.sample_us = 0;
	_watch.steps = 0;
	_watch.worst_us = 0;
	_watch.missed = 0;
}

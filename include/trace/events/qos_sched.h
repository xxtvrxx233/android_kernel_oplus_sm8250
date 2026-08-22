/* SPDX-License-Identifier: GPL-2.0-only */
#undef TRACE_SYSTEM
#define TRACE_SYSTEM qos_sched

#if !defined(_TRACE_QOS_SCHED_H) || defined(TRACE_HEADER_MULTI_READ)
#define _TRACE_QOS_SCHED_H

#include <linux/sched.h>
#include <linux/tracepoint.h>

TRACE_EVENT(qos_sched_decision,

	TP_PROTO(struct task_struct *task, int level, int eas_cpu,
		 int final_cpu, int reason, int mode),

	TP_ARGS(task, level, eas_cpu, final_cpu, reason, mode),

	TP_STRUCT__entry(
		__array(char, comm, TASK_COMM_LEN)
		__field(pid_t, pid)
		__field(int, level)
		__field(int, eas_cpu)
		__field(int, final_cpu)
		__field(int, reason)
		__field(int, mode)
	),

	TP_fast_assign(
		memcpy(__entry->comm, task->comm, TASK_COMM_LEN);
		__entry->pid = task->pid;
		__entry->level = level;
		__entry->eas_cpu = eas_cpu;
		__entry->final_cpu = final_cpu;
		__entry->reason = reason;
		__entry->mode = mode;
	),

	TP_printk("comm=%s pid=%d level=%d eas_cpu=%d final_cpu=%d reason=%d mode=%d",
		  __entry->comm, __entry->pid, __entry->level,
		  __entry->eas_cpu, __entry->final_cpu, __entry->reason,
		  __entry->mode)
);

#endif /* _TRACE_QOS_SCHED_H */

#undef TRACE_INCLUDE_FILE
#define TRACE_INCLUDE_FILE qos_sched
#include <trace/define_trace.h>

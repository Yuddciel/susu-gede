// SPDX-License-Identifier: GPL-2.0
#include <linux/init.h>
#include <linux/kernel_stat.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>

/*
 * /proc/softirqs  ... display the number of softirqs
 */
static int show_softirqs(struct seq_file *p, void *v)
{
	int i, j;

	seq_puts(p, "                    ");
	for_each_possible_cpu(i)
		seq_printf(p, "CPU%-8d", i);
	seq_putc(p, '\n');

	for (i = 0; i < NR_SOFTIRQS; i++) {
		seq_printf(p, "%12s:", softirq_to_name[i]);
		for_each_possible_cpu(j)
		seq_putc(p, '\n');
	}
	return 0;
}

static int softirqs_open(struct inode *inode, struct file *file)
{
	return single_open(file, show_softirqs, NULL);
}

static const struct file_operations proc_softirqs_operations = {
	.open		= softirqs_open,
	.read		= seq_read,
	.llseek		= seq_lseek,
	.release	= single_release,
};

static int __init proc_softirqs_init(void)
{
	proc_create("softirqs", 0, NULL, &proc_softirqs_operations);
	return 0;
}
fs_initcall(proc_softirqs_init);

from __future__ import print_function

import os.path

class NextSource(gdb.Command):
    def __init__(self):
        super().__init__(
            'ns',
            gdb.COMMAND_BREAKPOINTS,
            gdb.COMPLETE_NONE,
            False
        )
    def invoke(self, argument, from_tty):
        argv = gdb.string_to_argv(argument)
        if argv:
            if len(argv) > 1:
                gdb.write('Usage:\nns [source-name]]\n')
                return
            source = argv[0]
            full_path = False if os.path.basename(source) == source else True

        else:
            source = gdb.selected_frame().find_sal().symtab.fullname()
            full_path = True
        thread = gdb.inferiors()[0].threads()[0]
        while True:
            message = gdb.execute('next', to_string=True)
            if not thread.is_valid():
                break
            try:
                cur_source = gdb.selected_frame().find_sal().symtab.fullname()
                if not full_path:
                    cur_source = os.path.basename(cur_source)
            except:
                break
            else:
                if source == cur_source:
                    break
NextSource()

sys.path.append("/usr/local/lib/python3.10/dist-packages")
import duel

#from pretty_printer import PrettyPrinter
#
#@PrettyPrinter
#def st_bitmap(val):
#    s=''
#    for i in range((val['n_bits']+31)//32):
#        s = format(int(val['bitmap'][i]), '032b') + s
#    return "b'" + s[-int(val['n_bits']):] + "'"

class GrepCmd (gdb.Command):
    """Execute command, but only show lines matching the pattern
    Usage: grep_cmd <cmd> <pattern> """

    def __init__ (_):
        super ().__init__ ("grep_cmd", gdb.COMMAND_STATUS)

    def invoke (_, args_raw, __):
        args = gdb.string_to_argv(args_raw)
        if len(args) != 2:
            print("Wrong parameters number. Usage: grep_cmd <cmd> <pattern>")
        else:
            for line in gdb.execute(args[0], to_string=True).splitlines():
                if args[1] in line:
                    print(line)

GrepCmd


import gdb

class FilterThreadsByFunction(gdb.Command):
    """Filter threads by function name and display their backtraces."""

    def __init__(self):
        super(FilterThreadsByFunction, self).__init__("filter_threads", gdb.COMMAND_USER)

    def invoke(self, arg, from_tty):
        func_name = arg.strip()
        if not func_name:
            print("Usage: filter_threads <function_name>")
            return

        matching_threads = []

        # Iterate through all threads
        for thread in gdb.inferiors()[0].threads():
            thread.switch()
            bt = gdb.execute("bt -frame-arguments none -frame-info short-location -no-filters", to_string=True)  # Get backtrace

            # Check if the function name is in the backtrace
            if func_name in bt:
                matching_threads.append((thread.num, thread))

        # Print results
        if matching_threads:
            for thread_id, thread in matching_threads:
                thread.switch()
                print(f"\nThread {thread_id}:")
                gdb.execute("bt")
        else:
            print(f"No threads found with function name '{func_name}'.")

FilterThreadsByFunction()

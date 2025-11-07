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

import gdb.printing
import threading

class LexIdentColumnPrinter:
    "Pretty-printer for Lex_ident_column"
    _recursion_guard = threading.local()

    def __init__(self, val):
        self.val = val

    def to_string(self):
        if getattr(self._recursion_guard, "inside", False):
            return "<recursive>"

        self._recursion_guard.inside = True
        try:
            str_ptr = self.val['str']
            length_val = int(self.val['length'])

            addr_str = str(str_ptr.cast(gdb.lookup_type('void').pointer()))

            try:
                if addr_str != '0x0':
                    str_val = f'{addr_str} "{str_ptr.string()}"'
                else:
                    str_val = addr_str
            except:
                str_val = addr_str

            return f'{{{str_val}, {length_val}}}'
        finally:
            self._recursion_guard.inside = False

class ListPrinter:
    _recursion_guard = threading.local()

    def __init__(self, val):
        self.val = val

    def to_string(self):
        # Returning None disables the '= {...}' summary printing
        return None

    def children(self):
        if getattr(self._recursion_guard, 'active', False):
            return
        self._recursion_guard.active = True
        try:
            yield ('first', self.val['first'])
            yield ('last', self.val['last'])
            yield ('elements', self.val['elements'])
        except Exception:
            return
        finally:
            self._recursion_guard.active = False

class ExactMatchCollection:
    """
    Custom pretty-printer collection that uses exact type name matching
    as a lightweight alternative to GDB's RegexpCollectionPrettyPrinter,
    which matches type names using regular expressions.
    """
    def __init__(self):
        self.printers = {
            "LEX_CSTRING": LexIdentColumnPrinter,
            "Lex_ident_column": LexIdentColumnPrinter,
            "Lex_ident_fs": LexIdentColumnPrinter,
            "Lex_ident_db": LexIdentColumnPrinter,
            "Lex_ident_table": LexIdentColumnPrinter,
            # Add more type printers here if needed
        }
        self.name = "exact_match_printer_collection"

    def __call__(self, val):
        type_name = str(val.type)
        if type_name in self.printers:
            return self.printers[type_name](val)
        return None

def register_printers():
    # Remove any existing global printers with the same name to avoid duplicates
    to_remove = [pp for pp in gdb.pretty_printers if getattr(pp, 'name', None) == "exact_match_printer_collection"]
    for pp in to_remove:
        gdb.pretty_printers.remove(pp)

    printer = ExactMatchCollection()
    gdb.pretty_printers.append(printer)

def register_printers():
    # Remove old printers with the same name to avoid duplicates
    to_remove = [pp for pp in gdb.pretty_printers if getattr(pp, 'name', None) == "exact_match_printer_collection"]
    for pp in to_remove:
        gdb.pretty_printers.remove(pp)
    gdb.pretty_printers.append(ExactMatchCollection())
    # Create a RegexpCollectionPrettyPrinter and add List<> template match
    list_printers = gdb.printing.RegexpCollectionPrettyPrinter("list_printers")
    list_printers.add_printer('List', '^List<.*>$', ListPrinter)
    # Register globally
    gdb.printing.register_pretty_printer(None, list_printers)

def on_first_objfile(event):
    register_printers()
    gdb.events.new_objfile.disconnect(on_first_objfile)

gdb.events.new_objfile.connect(on_first_objfile)

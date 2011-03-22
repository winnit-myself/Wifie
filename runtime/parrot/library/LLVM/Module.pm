#! nqp
=begin Description
LLVM Module.
=end Description


class LLVM::Module is LLVM::Opaque {
    multi method create($name) {
        self.new.wrap( LLVM::call("ModuleCreateWithName", $name) );
    }

    method verify($action?) {
        0 == LLVM::call(
            "VerifyModule",
            self,
            $action // LLVM::VERIFYER_FAILURE_ACTION.RETURN_STATUS,
            ""
        );
    }

    method dump() {
        LLVM::call("DumpModule", self);
    }

    method add_function ($name, $return, *@args, :$va_args?) {
        LLVM::Function.create(
            LLVM::call("AddFunction", self, $name,
                LLVM::Type::function($return, |@args, :va_args($va_args))
            )
        );
    }

#/** See Module::addTypeName. */
    # LLVMAddTypeName => "Iptp",
    method add_type_name(Str $name, $type) {
        LLVM::call("AddTypeName", self, $name, $type);
    }

    # LLVMDeleteTypeName => "vpt",
    method delete_type_name(Str $name) {
        LLVM::call("DeleteTypeName", self, $name);
    }

    # LLVMGetTypeByName => "ppt",
    method get_type_name(Str $name) {
        LLVM::call("GetTypeByName", self, $name);
    }
};

# vim: ft=perl6
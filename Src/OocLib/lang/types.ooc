import Hal/Display, Printf

include stdbool, stdint, c_types
include ./array

/**
 * objects
 */
Object: abstract class {

    class: Class

    /// Instance initializer: set default values for a new instance of this class
    __defaults__: func {}

    /// Finalizer: cleans up any objects belonging to this instance
    __destroy__: func {}

    /** return true if *class* is a subclass of *T*. */
    instanceOf: final func (T: Class) -> Bool {
        if(!this) return false
        class inheritsFrom(T)
    }

    /*
    toString: func -> String {
        "%s@%p" format(class name, this)
    }
    */

}

Class: abstract class {

    /// Number of octets to allocate for a new instance of this class
    instanceSize: SizeT

    /// Number of octets to allocate to hold an instance of this class
    /// it's different because for classes, instanceSize may greatly
    /// vary, but size will always be equal to the size of a Pointer.
    /// for basic types (e.g. Int, Char, Pointer), size == instanceSize
    size: SizeT

    /// Human readable representation of the name of this class
    name: String

    /// Pointer to instance of super-class
    super: const Class

    /// Create a new instance of the object of type defined by this class
    alloc: final func ~_class -> Object {
        object := gc_malloc(instanceSize) as Object
        if(object) {
            object class = this
        }
        return object
    }

    inheritsFrom: final func ~_class (T: Class) -> Bool {
        if(this == T) return true
        return (super ? super inheritsFrom(T) : false)
    }

}

Array: cover from _lang_array__Array {
    length: extern Int
    data: extern Pointer
}

/**
 * Pointer type
 */
Void: cover from void
Pointer: cover from void*

NULL: unmangled Pointer = 0

/**
 * character and pointer types
 */
//__char: extern(char) Void
__char_ary: extern(__CHAR_ARY) Void
Char: cover from char {
    println: func {
        Display printChar(this)
        Display printChar('\n')
    }

    print: func {
        Display printChar(this)
    }

    // check for an alphanumeric character
    isAlphaNumeric: func -> Bool {
        isAlpha() || isDigit()
    }

    // check for an alphabetic character
    isAlpha: func -> Bool {
        isLower() || isUpper()
    }

    // check for a lowercase alphabetic character
    isLower: func -> Bool {
        this >= 'a' && this <= 'z'
    }

    // check for an uppercase alphabetic character
    isUpper: func -> Bool {
        this >= 'A' && this <= 'Z'
    }

    // check for a decimal digit (0 through 9)
    isDigit: func -> Bool {
        this >= '0' && this <= '9'
    }

    // check for a hexadecimal digit (0 1 2 3 4 5 6 7 8 9 a b c d e f A B C D E F)
    isHexDigit: func -> Bool {
        isDigit() ||
        (this >= 'A' && this <= 'F') ||
        (this >= 'a' && this <= 'f')
    }

    // check for a control character
    isControl: func -> Bool {
        (this >= 0 && this <= 31) || this == 127
    }

    // check for any printable character except space
    isGraph: func -> Bool {
        isPrintable() && this != ' '
    }

    // check for any printable character including space
    isPrintable: func -> Bool {
        this >= 32 && this <= 126
    }

    // check for any printable character which is not a space or an alphanumeric character
    isPunctuation: func -> Bool {
        isPrintable() && !isAlphaNumeric() && this != ' '
    }

    // check for white-space characters: space, form-feed ('\f'), newline ('\n'),
    // carriage return ('\r'), horizontal tab ('\t'), and vertical tab ('\v')
    isWhitespace: func -> Bool {
        this == ' '  ||
        this == '\f' ||
        this == '\n' ||
        this == '\r' ||
        this == '\t' ||
        this == '\v'
    }

    // check for a blank character; that is, a space or a tab
    isBlank: func -> Bool {
        this == ' ' || this == '\t'
    }

    toInt: func -> Int {
        if (isDigit()) {
            return (this - '0')
        }
        return -1
    }
}

UChar: cover from unsigned char extends Char

String: cover from Char* {
    new: static func~withLength (length: Int) -> This {
        result := gc_malloc(length + 1) as This
        result[length] = '\0'
        result
    }

    length: func -> SizeT {
        i := 0
        while (this@) {
            this += 1
            i += 1
        }
        return i
    }

    println: func {
        println(this)
    }

    print: func {
        print(this)
    }

    format: func (...) -> This {
        list:VaList

        va_start(list, this)

        length := vsnprintf(null, 0, this, list)
        output := This new(length)
        va_end(list)

        va_start(list, this)
        vsnprintf(output, length + 1, this, list)
        va_end(list)

        return output
    }
}

/**
 * integer types
 */
__void: extern(void) Void
__int: extern(int) Void
__uint: extern(uint32_t) Void
Int: cover from int
UInt: cover from unsigned int
Short: cover from short
UShort: cover from unsigned short
Long: cover from long
ULong: cover from unsigned long
LLong: cover from long long
ULLong: cover from unsigned long long

/**
 * fixed-size integer types
 */
Int8: cover from int8_t
Int16: cover from int16_t
Int32: cover from int32_t
Int64: cover from int64_t

UInt8:  cover from uint8_t
UInt16: cover from uint16_t
UInt32: cover from uint32_t
UInt64: cover from uint64_t

Bool: cover from bool

/**
 * real types
 */
Float: cover from float
Double: cover from double
LDouble: cover from long double

/**
 * custom types
 */
Range: cover {
    min, max: Int

    new: static func (.min, .max) -> This {
        this: This
        this min = min
        this max = max
        return this
    }
}

SizeT: cover from size_t

/**
 * exceptions
 */
Exception: class {

    origin: Class
    msg : String

    init: func ~originMsg (=origin, =msg) {}
    init: func ~noOrigin (=msg) {}
    
    crash: func {
        x := 0
        x = 1 / x
        printf("%d", x)
    }
    
    getMessage: func -> String {
        //max := const 1024
        max : const Int = 1024
        buffer := gc_malloc(max) as String
        if(origin) snprintf(buffer, max, "[%s in %s]: %s\n", this as Object class name, origin name, msg)
        else snprintf(buffer, max, "[%s]: %s\n", this as Object class name, msg)
        return buffer
    }
    
    print: func {
        printf("%s", getMessage())
    }
    
    throw: func {
        print()
        crash()
    }

}

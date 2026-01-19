//
//  Symbols.swift
//  NM_View
//
//  Created by Aryan Rogye on 1/18/26.
//

struct Symbols {
    let symbolType: SymbolType
    let index: Int
}

enum SymbolType: String, CaseIterable {
    case T          = " T "
    case t          = " t "
    case S          = " S "
    case s          = " s "
    case D          = " D "
    case d          = " d "
    case B          = " B "
    case b          = " b "
    case U          = " U "
    case W          = " W "
    case w          = " w "
    case R          = " R "
    case r          = " r "
    case C          = " C "
    case I          = " I "
    case A          = " A "
    case Question   = " ? "
    
    var description: String {
        switch self {
        case .T:
            return "Exported function or code symbol in the TEXT segment (globally visible)"
        case .t:
            return "Local/private function or code symbol in the TEXT segment"
            
        case .S:
            return "Exported constant or read-only data symbol (often literal tables or metadata)"
        case .s:
            return "Local constant or read-only data symbol"
            
        case .D:
            return "Exported initialized global data symbol"
        case .d:
            return "Local initialized data symbol"
            
        case .B:
            return "Exported uninitialized global data symbol (BSS segment)"
        case .b:
            return "Local uninitialized data symbol (BSS segment)"
            
        case .U:
            return "Undefined external symbol (imported from another binary or framework)"
            
        case .W:
            return "Weak exported symbol (can be overridden by another definition)"
        case .w:
            return "Weak undefined symbol (optional import)"
            
        case .R:
            return "Exported read-only data symbol"
        case .r:
            return "Local read-only data symbol"
            
        case .C:
            return "Common symbol (legacy uninitialized global, resolved at link time)"
            
        case .I:
            return "Indirect symbol reference (symbol points to another symbol)"
        case .A:
            return "Absolute symbol (address is fixed and not relocatable)"
        case .Question:
            return "Unknown or debug-only symbol type"
        }
    }
}

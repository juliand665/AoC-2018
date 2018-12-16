// Created by Julian Dunskus

import Foundation

enum Operation: CaseIterable {
	case addr, addi
	case mulr, muli
	case banr, bani
	case borr, bori
	case setr, seti
	case gtir, gtri, gtrr
	case eqir, eqri, eqrr
	
	func evaluate(a: Int, b: Int, register: (Int) -> Int) -> Int {
		switch self {
		case .addr: return register(a) + register(b)
		case .addi: return register(a) + b
			
		case .mulr: return register(a) * register(b)
		case .muli: return register(a) * b
			
		case .banr: return register(a) & register(b)
		case .bani: return register(a) & b
			
		case .borr: return register(a) | register(b)
		case .bori: return register(a) | b
			
		case .setr: return register(a)
		case .seti: return a
			
		case .gtir: return a > register(b) ? 1 : 0
		case .gtri: return register(a) > b ? 1 : 0
		case .gtrr: return register(a) > register(b) ? 1 : 0
			
		case .eqir: return a == register(b) ? 1 : 0
		case .eqri: return register(a) == b ? 1 : 0
		case .eqrr: return register(a) == register(b) ? 1 : 0
		}
	}
}

struct Instruction: Parseable {
	var opcode: Int
	var a, b, c: Int
	
	init(from parser: inout Parser) {
		self.opcode = parser.readInt()
		parser.consume(while: " ")
		self.a = parser.readInt()
		parser.consume(while: " ")
		self.b = parser.readInt()
		parser.consume(while: " ")
		self.c = parser.readInt()
	}
}

struct Sample: Parseable {
	let before, after: [Int]
	let instruction: Instruction
	
	init(from parser: inout Parser) {
		func parseState() -> [Int] {
			parser.consume(through: "[")
			defer { parser.consume("]") }
			return Array(from: &parser)
		}
		
		self.before = parseState()
		parser.consume("\n")
		self.instruction = Instruction(from: &parser)
		parser.consume("\n")
		self.after = parseState()
	}
	
	func works(with operation: Operation) -> Bool {
		return after[instruction.c] == operation.evaluate(a: instruction.a, b: instruction.b) { before[$0] }
	}
}

let parts = input().components(separatedBy: "\n\n\n\n")
let samples = parts.first!.components(separatedBy: "\n\n").map(Sample.init)
let program = parts.last!.lines().map(Instruction.init)

let matches = samples.map {
	(opcode: $0.instruction.opcode, operations: Set(Operation.allCases.filter($0.works(with:))))
}

print(matches.count { $0.operations.count >= 3 }, "of the samples behave like 3+ opcodes")

var options = Dictionary(matches, uniquingKeysWith: { $0.intersection($1) })
var opcodes: [Int: Operation] = [:]
while let (opcode, operations) = options.first(where: { $0.value.count == 1 }) {
	let operation = operations.first!
	options[opcode] = nil
	opcodes[opcode] = operation
	options.values.mapInPlace { $0.remove(operation) }
}

assert(opcodes.count == 16)

var state = Array(repeating: 0, count: 4)
for instruction in program {
	state[instruction.c] = opcodes[instruction.opcode]!.evaluate(a: instruction.a, b: instruction.b) { state[$0] } 
}
print("state after program:", state)

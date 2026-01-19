import Foundation

enum BoyerMoore {
    // We will be using Boyer-Moore for pattern matching
    // https://www.geeksforgeeks.org/dsa/boyer-moore-algorithm-for-pattern-searching/
    // My First Time ever Implementing this algorithm, should be fun!

    // Dont know yet what the output will be just learning the algorithm
    // by reading code not really the best way to learn but
    // thats how i learn best
    //
    // Converting Python Code from example to Swift
    static func search(pattern: String, text: String) -> [Int] {
        let patternUnits = Array(pattern.utf16)
        let textUnits = Array(text.utf16)

        // Starts of by getting the length of the pattern and text
        let patternLength = patternUnits.count
        let textLength = textUnits.count

        guard patternLength > 0, patternLength <= textLength else { return [] }

        var badChar = Array(repeating: -1, count: 65_536)
        badCharHeuristic(patternUnits: patternUnits, patternLength: patternLength, badChar: &badChar)

        var indexes: [Int] = []
        var s = 0

        while s <= textLength - patternLength {
            var j = patternLength - 1

            /*
             * Keep reducing index j of pattern while
             * characters of pattern and text are
             * matching at this shift s
             */
            while j >= 0 && patternUnits[j] == textUnits[s + j] {
                j -= 1
            }

            /*
             * If the pattern is present at current
             * shift, then index j will become -1 after
             * the above loop
             */
            if j < 0 {
                indexes.append(s)

                /* Shift the pattern so that the next
                 * character in text aligns with the last
                 * occurrence of it in pattern.
                 * The condition s+m < n is necessary for
                 * the case when pattern occurs at the end
                 * of text
                 * txt[s+m] is character after the pattern
                 * in text
                 */
                if s + patternLength < textLength {
                    let nextChar = textUnits[s + patternLength]
                    s += patternLength - badChar[Int(nextChar)]
                } else {
                    s += 1
                }
            } else {
                /* Shift the pattern so that the bad
                 * character in text aligns with the last
                 * occurrence of it in pattern. The max
                 * function is used to make sure that we get
                 * a positive shift. We may get a negative
                 * shift if the last occurrence  of bad
                 * character in pattern is on the right side
                 * of the current character.
                 */
                let badIndex = badChar[Int(textUnits[s + j])]
                s += max(1, j - badIndex)
            }
        }

        return indexes
    }

    private static func badCharHeuristic(
        patternUnits: [UInt16],
        patternLength: Int,
        badChar: inout [Int]
    ) {
        // Initialize all occurrence as -1
        for i in 0..<badChar.count {
            badChar[i] = -1
        }

        for i in 0..<patternLength {
            // Lets break this apart
            // Int(patternUnits[i])
            // Int(patternUnits[i]) is the integer value of the character at index i
            // if our pattern was "ABC":
            //
            // i = 0 -> 'A' = 65 // ASCII Value
            // i = 1 -> 'B' = 66 // ASCII Value
            // i = 2 -> 'C' = 67 // ASCII Value

            let index = Int(patternUnits[i])

            badChar[index] = i

            // so now badChar is looking like: [-1,-1,-1,-1,-1, ... 0, 1, 2, ...]
        }
    }
}

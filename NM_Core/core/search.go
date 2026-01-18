package core

type Search struct {
	SearchIn string
	Query    string
}

const (
	NO_OF_CHARS = 256
)

// We Will be using Boyer-Moore for pattern matching
// https://www.geeksforgeeks.org/dsa/boyer-moore-algorithm-for-pattern-searching/
// My First Time ever Implementing this algorithm, should be fun!

// Dont know yet what the output will be just learning the algorithm
// by reading code not really the best way to learn but
// thats how i learn best
//
// Converting Python Code from example to Golang
func BoyerMoore(pattern string, text string) []int {

	// Starts of by getting the length of the pattern and text
	patternLength := len(pattern)
	textLength := len(text)

	badChar := make([]int, NO_OF_CHARS)

	badCharHeuristic(pattern, patternLength, badChar)

	var indexes []int

	s := 0

	for s <= (textLength - patternLength) {

		j := patternLength - 1

		/*
		 * Keep reducing index j of pattern while
		 * characters of pattern and text are
		 * matching at this shift s
		 */
		for j >= 0 && pattern[j] == text[s+j] {
			j--
		}

		/*
		 * If the pattern is present at current
		 * shift, then index j will become -1 after
		 * the above loop
		 */
		if j < 0 {
			indexes = append(indexes, s)

			/* Shift the pattern so that the next
			 * character in text aligns with the last
			 * occurrence of it in pattern.
			 * The condition s+m < n is necessary for
			 * the case when pattern occurs at the end
			 * of text
			 * txt[s+m] is character after the pattern
			 * in text
			 */
			if (s + patternLength) < textLength {
				s += patternLength - badChar[int(text[s+patternLength])]
			} else {
				s++
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
			s += max(1, j-badChar[int(text[s+j])])
		}
	}

	return indexes
}

func badCharHeuristic(pattern string, patternLength int, badChar []int) {

	// Initialize all occurrence as -1
	for i := 0; i < NO_OF_CHARS; i++ {
		badChar[i] = -1
	}

	for i := 0; i < patternLength; i++ {

		// Lets break this apart
		// int(pattern[i])
		// int(pattern[i]) is the integer value of the character at index i
		// if our pattern was "ABC":
		//
		// i = 0 → 'A' = 65 // ASCII Value
		// i = 1 → 'B' = 66 // ASCII Value
		// i = 2 → 'C' = 67 // ASCII Value

		index := int(pattern[i])

		badChar[index] = i

		// so now badChar is looking like: [-1,-1,-1,-1,-1, ... 0, 1, 2, ...]
	}
}

func (s *Search) Search() ([]int, error) {

	indexes := BoyerMoore(s.Query, s.SearchIn)

	return indexes, nil
}

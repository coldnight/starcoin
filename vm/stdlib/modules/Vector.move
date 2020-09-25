address 0x1 {

// A variable-sized container that can hold both unrestricted types and resources.
module Vector {
    spec module {
        pragma verify;
        pragma aborts_if_is_strict;
    }

    native public fun empty<Element>(): vector<Element>;

    // Return the length of the vector.
    native public fun length<Element>(v: &vector<Element>): u64;

    // Acquire an immutable reference to the ith element of the vector.
    native public fun borrow<Element>(v: &vector<Element>, i: u64): &Element;

    // Add an element to the end of the vector.
    native public fun push_back<Element>(v: &mut vector<Element>, e: Element);

    // Get mutable reference to the ith element in the vector, abort if out of bound.
    native public fun borrow_mut<Element>(v: &mut vector<Element>, idx: u64): &mut Element;

    // Pop an element from the end of vector, abort if the vector is empty.
    native public fun pop_back<Element>(v: &mut vector<Element>): Element;

    // Destroy the vector, abort if not empty.
    native public fun destroy_empty<Element>(v: vector<Element>);

    // Swaps the elements at the i'th and j'th indices in the vector.
    native public fun swap<Element>(v: &mut vector<Element>, i: u64, j: u64);

    // Return an vector of size one containing `e`
    public fun singleton<Element>(e: Element): vector<Element> {
        let v = empty();
        push_back(&mut v, e);
        v
    }
    spec fun singleton {
        // TODO(wrwg): when using opaque here, we get verification errors.
        // pragma opaque;
        aborts_if false;
        ensures result == spec_singleton(e);
    }
    spec module {
        define spec_singleton<Element>(e: Element): vector<Element> {
            singleton_vector(e)
        }
    }

    // Reverses the order of the elements in the vector in place.
    public fun reverse<Element>(v: &mut vector<Element>) {
        let len = length(v);
        if (len == 0) return ();

        let front_index = 0;
        let back_index = len -1;
        while (front_index < back_index) {
            swap(v, front_index, back_index);
            front_index = front_index + 1;
            back_index = back_index - 1;
        }
    }

    // Moves all of the elements of the `other` vector into the `lhs` vector.
    public fun append<Element>(lhs: &mut vector<Element>, other: vector<Element>) {
        reverse(&mut other);
        while (!is_empty(&other)) push_back(lhs, pop_back(&mut other));
        destroy_empty(other);
    }

    // Return true if the vector has no elements
    public fun is_empty<Element>(v: &vector<Element>): bool {
        length(v) == 0
    }

    // Return true if `e` is in the vector `v`
    public fun contains<Element>(v: &vector<Element>, e: &Element): bool {
        let i = 0;
        let len = length(v);
        while (i < len) {
            if (borrow(v, i) == e) return true;
            i = i + 1;
        };
        false
    }

    // Return (true, i) if `e` is in the vector `v` at index `i`.
    // Otherwise returns (false, 0).
    public fun index_of<Element>(v: &vector<Element>, e: &Element): (bool, u64) {
        let i = 0;
        let len = length(v);
        while (i < len) {
            if (borrow(v, i) == e) return (true, i);
            i = i + 1;
        };
        (false, 0)
    }


    // Remove the `i`th element E of the vector, shifting all subsequent elements
    // It is O(n) and preserves ordering
    public fun remove<Element>(v: &mut vector<Element>, i: u64): Element {
        let len = length(v);
        // i out of bounds; abort
        if (i >= len) abort 10;

        len = len - 1;
        while (i < len) swap(v, i, { i = i + 1; i });
        pop_back(v)
    }

    // Remove the `i`th element E of the vector by swapping it with the last element,
    // and then popping it off
    // It is O(1), but does not preserve ordering
    public fun swap_remove<Element>(v: &mut vector<Element>, i: u64): Element {
        let last_idx = length(v) - 1;
        swap(v, i, last_idx);
        pop_back(v)
    }

    public fun split<Element: copyable>(v: &vector<Element>, sub_len: u64): vector<vector<Element>> {
        let result = empty<vector<Element>>();
        let len = length(v) / sub_len;

        let rem = 0;
        if (len * sub_len < length(v)) {
            rem = length(v) - len * sub_len;
        };

        let i = 0;
        while (i < len) {
            let sub = empty<Element>();
            let j = 0;
            while (j < sub_len) {
                let index = sub_len * i + j;
                push_back(&mut sub, *borrow(v, index));
                j = j + 1;
            };
            push_back<vector<Element>>(&mut result, sub);
            i = i + 1;
        };

        if (rem > 0) {
            let sub = empty<Element>();
            let index = length(v) - rem;
            while (index < length(v)) {
                push_back(&mut sub, *borrow(v, index));
                index = index + 1;
            };
            push_back<vector<Element>>(&mut result, sub);
        };
        result
    }

    spec fun split {
        pragma verify = false;
    }
    // ------------------------------------------------------------------------
    // Specification
    // ------------------------------------------------------------------------

    /// # Module specifications

    spec module {
        /// Auxiliary function to check whether a vector contains an element.
        define spec_contains<Element>(v: vector<Element>, e: Element): bool {
            exists x in v: x == e
        }

        /// Auxiliary function to check if `v1` is equal to the result of adding `e` at the end of `v2`
        define eq_push_back<Element>(v1: vector<Element>, v2: vector<Element>, e: Element): bool {
            len(v1) == len(v2) + 1 &&
            v1[len(v1)-1] == e &&
            v1[0..len(v1)-1] == v2[0..len(v2)]
        }

        /// Auxiliary function to check if `v` is equal to the result of concatenating `v1` and `v2`
        define eq_append<Element>(v: vector<Element>, v1: vector<Element>, v2: vector<Element>): bool {
            len(v) == len(v1) + len(v2) &&
            v[0..len(v1)] == v1 &&
            v[len(v1)..len(v)] == v2
        }

        // Auxiliary function to check if `v1` is equal to the result of removing the first element of `v2`
        define eq_pop_front<Element>(v1: vector<Element>, v2: vector<Element>): bool {
            len(v1) + 1 == len(v2) &&
            v1 == v2[1..len(v2)]
        }
    }

    spec fun length {
        pragma intrinsic = true;
    }
    spec fun borrow {
        pragma intrinsic = true;
    }

    spec fun reverse {
        pragma intrinsic = true;
    }

    spec fun append {
        pragma intrinsic = true;
    }

    spec fun is_empty {
        pragma intrinsic = true;
    }

    spec fun contains {
        pragma intrinsic = true;
    }

    spec fun index_of {
        pragma intrinsic = true;
    }

    spec fun remove {
        pragma intrinsic = true;
    }

    spec fun swap_remove {
        pragma intrinsic = true;
    }
}

}

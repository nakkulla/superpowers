# Brainstorming Quick Edit Owner Alignment Design
Parent bead: superpowers-a91

**Status:** Draft for review  
**Date:** 2026-04-22

## Problem

`quick_edit`의 owner contract가 superpowers 쪽에서는 아직 명확하게 고정되어 있지 않다.
이번 변경의 owner boundary는 **brainstorming이 quick_edit를 언제/어떻게 추천하는지**에 한정되며, normal spec path의 parent-bead linkage 규칙을 다시 정의하는 작업은 아니다.
현재 흐름에서는 `quick_edit`가 다음처럼 오해될 여지가 있다.

- 작은 작업이면 기본 spec/plan 경로를 건너뛰는 일반 shortcut,
- parent issue에 붙는 상태 라벨,
- `writing-plans`가 해석하거나 이어받아야 하는 plan-optional workflow.

하지만 이번 정렬 작업에서 필요한 의미는 더 좁고 보수적이다.
`quick_edit`는 broad workflow 대체물이 아니라, `brainstorming` 단계에서만 판단되는 예외 fast-path여야 한다.

## Goal

`skills/brainstorming/SKILL.md`에서 `quick_edit`를 다음 의미로 명확히 고정한다.

1. `quick_edit`는 기본 경로가 아니라 brainstorming 단계의 **보수적 preflight 예외 경로**다.
2. agent는 먼저 이 작업이 정말 spec 없이 끝낼 수 있는 좁은 one-shot 수정인지 짧게 판단한다.
3. 그 판단을 통과한 경우에만 `quick_edit`를 추천한다.
4. `quick_edit`가 선택 확정되면, Beads-enabled repo에서는 **새 standalone execution issue를 생성**하고 그 **새 issue에 `quick_edit` 라벨**을 붙인다.
5. 이 contract는 `brainstorming`이 소유하며, 이번 변경에서 `writing-plans`는 수정하지 않는다.

여기서 새 issue 생성 규칙은 **brainstorming이 현재 요청을 normal spec path 대신 quick_edit path로 보내기로 결정한 경우**에만 적용된다.
이미 normal spec path로 들어가서 parent bead에 spec을 연결하는 기존 흐름은 그대로 유지된다.

## Non-Goals

- `skills/writing-plans/SKILL.md` 변경
- `quick_edit`를 plan workflow 안으로 편입하는 작업
- parent linkage 또는 dependency wiring 의무화
- merge/close/post-implementation 정책 정의
- cross-skill 전체 contract 재설계
- quick_edit를 모든 작은 작업의 기본 경로로 만드는 것

## Current Behavior and Risk

현재 superpowers 쪽 wording이 느슨하면 아래 같은 drift가 생길 수 있다.

- spec이 필요한 작업도 "작아 보인다"는 이유로 `quick_edit`로 밀어 넣음
- `quick_edit` 라벨이 parent issue의 상태처럼 오해됨
- plan-less 예외 경로가 `writing-plans`와 연결된 것처럼 읽힘
- skill owner boundary가 흐려져 downstream wording과 semantic drift가 발생함

이 drift는 특히 shared contract wording, policy alignment, multi-step 변경처럼 실제로는 설계 판단이 필요한 작업에서 문제를 만든다.

## Proposed Behavior

### Ownership boundary

이번 변경의 owner는 `brainstorming`이다.
`quick_edit`는 brainstorming 단계에서만 선별되는 예외 경로이며, 이번 작업에서는 `writing-plans`가 이를 해석하거나 라벨링하지 않는다.

### Decision rule

`quick_edit`는 "작아 보이는지"가 아니라 아래 질문에 보수적으로 yes일 때만 선택된다.

- 하나의 좁은 실행 단위인가?
- spec 없이도 의도 오해 위험이 낮은가?
- plan 없이도 검증 경로가 바로 보이는가?
- 실패해도 영향 범위가 작고 되짚기 쉬운가?

하나라도 애매하면 기본값은 normal brainstorming → spec 경로다.

### Allowed examples

다음은 `quick_edit`로 보낼 수 있는 대표 예시다.

- 작은 bugfix
- copy / text 수정
- config / flag / path 같은 국소 변경
- 영향 범위가 좁고 추가 설계 문서 없이 바로 검증 가능한 one-shot 수정

### Disallowed examples

다음은 `quick_edit`로 보내면 안 된다.

- multi-step 작업
- broad behavior change
- shared contract / policy wording alignment
- cross-skill 또는 cross-repo 성격의 변경
- 구현 전에 요구사항 정리나 설계 판단이 필요한 작업

이 기준에 따르면 `superpowers-a91` 같은 shared contract wording 정렬 작업은 `quick_edit`가 아니라 normal spec 경로가 맞다.

## Issue Handling Rule

이 규칙은 **`.beads/`와 `bd`가 사용 가능한 repo**에서의 quick-edit issue handling을 정의한다.

`quick_edit`가 선택 확정되면 brainstorming은:

1. 새 standalone issue를 생성한다.
2. 그 새 issue에 `quick_edit` 라벨을 붙인다.

이 라벨은 기존 parent issue의 상태 표식이 아니다.
새로 생성된 `quick_edit` execution unit의 shape를 나타내는 라벨이다.

이 standalone issue는 **spec-bearing parent를 대체하는 문서 anchor가 아니라**, spec 없이 바로 실행 가능한 narrow execution unit을 추적하기 위한 tracker artifact다.
따라서 normal brainstorming → spec path에서 쓰이는 기존 parent linkage / `spec_id` / `reviewed:spec` 규칙은 이 변경으로 바뀌지 않는다.

최소 shape는 아래 정도만 요구한다.

- title/description은 현재 요청을 좁은 one-shot 실행 단위로 식별할 수 있어야 한다.
- user-facing 설명에서는 이것이 normal spec path의 parent bead가 아니라 quick_edit execution issue임을 구분해서 말한다.
- 기존 parent bead 라벨/상태를 대신하는 개념으로 다루지 않는다.

Beads가 없는 repo에서는 이 spec이 대체 tracker 동작까지 정의하지 않는다.
이 변경의 범위에서는 tracker가 없는 환경을 위해 별도 quick-edit issue flow를 만들지 않는다.

이번 변경에서는 아래를 요구하지 않는다.

- parent issue에 `quick_edit` 라벨 부여
- parent linkage 자동 생성
- `writing-plans`에서 quick_edit issue 후속 처리

## Required Skill Update

### `skills/brainstorming/SKILL.md`

다음 의미를 분명하게 반영해야 한다.

1. `quick_edit`는 기본 경로가 아니라 보수적 preflight 예외 경로다.
2. 허용/비허용 예시를 짧게 포함한다.
3. 애매하면 기본 경로는 normal brainstorming → spec 이라고 명시한다.
4. `quick_edit` 선택 확정 시, Beads가 있는 repo에서는 새 standalone issue 생성 + 새 issue에 `quick_edit` 라벨 부여를 명시한다.
5. parent linkage나 `writing-plans` 책임은 이 contract에 포함하지 않는다.
6. normal spec path의 parent linkage / `spec_id` 규칙을 바꾸지 않는다고 명시한다.

## Verification

1. `skills/brainstorming/SKILL.md`가 `quick_edit`를 기본 경로가 아닌 보수적 preflight 예외 경로로 설명하는지 확인한다.
2. 허용/비허용 예시가 짧고 명확하게 들어가는지 확인한다.
3. 애매한 경우 normal brainstorming → spec 경로로 남는다고 명시하는지 확인한다.
4. `quick_edit` 선택 확정 시, Beads가 있는 repo에서는 새 standalone issue 생성 규칙이 들어가는지 확인한다.
5. `quick_edit` 라벨 대상이 parent가 아니라 새로 생성된 issue라고 명시하는지 확인한다.
6. 새 standalone issue가 tracker artifact이며 normal spec path의 `spec_id` anchor를 대체하지 않는다고 명시하는지 확인한다.
7. `writing-plans` 수정이나 parent linkage 의무가 요구되지 않는지 확인한다.
8. 구현 후 `scripts/sync-local-plugin-copies.sh copy` 및 `scripts/sync-local-plugin-copies.sh verify`로 installed plugin copies 동기화를 확인한다.

## Risks and Mitigations

### Risk: `quick_edit`가 다시 default shortcut처럼 읽힘

**Mitigation:** `quick_edit`를 explicit preflight exception으로 정의하고, ambiguous cases는 기본 spec 경로로 남긴다.

### Risk: 라벨이 parent state처럼 오해됨

**Mitigation:** 라벨 대상을 "새로 생성된 quick-edit issue"로 명시하고 parent labeling을 비목표로 둔다.

### Risk: downstream plan workflow와 다시 섞임

**Mitigation:** 이번 변경의 owner를 brainstorming-only로 제한하고 `writing-plans` 변경을 비목표로 고정한다.

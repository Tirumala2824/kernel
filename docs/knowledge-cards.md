# Knowledge cards (Pest & Animal ID)

Curated, sourced cards that ground every Pest ID answer (guardrails §9). The LLM may rephrase and explain card content, but it never invents guidance.

- **File:** `app-ui/assets/knowledge/pest_cards.json`. data-operations loads it into the `knowledge_cards` table; embeddings are cached on the device.
- **Status:** every card ships with `"reviewStatus": "needs-expert-review"` until a named expert signs it off. Record sign-offs in `docs/decisions-log.md`.

## Schema
```jsonc
{
  "version": "kernel-cards-0.1",
  "cards": [
    {
      "id": "german_cockroach",              // snake_case, stable; the LLM's constrained label set
      "names": { "en": "German cockroach", "hi": "..." },  // en required; others optional (machine-drafted, flagged)
      "group": "insect",                      // insect | arachnid | rodent | reptile | other
      "safety": "caution",                    // low | caution | medicalRisk | venomous | protectedWildlife
      "extraSafety": [],                      // optional further levels that also apply, e.g. ["protectedWildlife"] on a snake
      "summary": "One or two plain sentences.",
      "signs": ["Pepper-like droppings ...", "Egg cases (oothecae) ..."],   // what a camera or mic can pick up
      "lookAlikes": ["american_cockroach", "..."],                          // card ids or plain names
      "healthRisks": ["Allergens and asthma triggers ..."],
      "safeSteps": ["Remove food and water sources ...", "Seal gaps ..."],  // non-chemical first; no poisons or doses; no trap steps
      "trapSteps": [],                        // optional; "where lawful" trap steps, hidden whenever a protected concern applies
      "callProfessionalWhen": ["Seen in daylight or in large numbers ..."],
      "firstAid": [],                         // pointers only ("seek medical care"); no home remedies
      "legal": null,                          // e.g. Wild Life (Protection) Act status for protected species
      "sources": ["https://..."],             // WHO, NCVBDC/ICMR, CDC, UC IPM, State Forest Dept, etc.
      "reviewStatus": "needs-expert-review"
    }
  ]
}
```

## Rules
- At least one primary public-health, agricultural-extension or wildlife-authority source per card.
- `safeSteps` must never name a pesticide, rodenticide, fumigant or dose. "Call a licensed pest-control professional" is allowed.
- Protected species (e.g. monitor lizards): `safety: protectedWildlife`, a `legal` text, and "do not harm, catch or injure it; contact the State Forest Department or a rescuer authorised by it".
- Venomous or medically important species: lead with keeping distance and getting medical care for bites or stings.
- Several levels: when more than one applies, set the primary `safety` and list the rest in `extraSafety`. For example, snakes are `venomous` + `protectedWildlife` (many Indian snakes are Schedule I/II), and bats and palm civets are `protectedWildlife` + `medicalRisk` (rabies, Nipah). Every applicable required sentence must be present.
- No glue or sticky boards for any animal. Trap or capture steps go only in `trapSteps`, never in `safeSteps`, and a protected animal's card has none. When any concern is `protectedWildlife` (for example the AI said palm squirrel but the user picked black rat), the app and the guide prompt leave out every card's `trapSteps`.
- No absolute claims ("safe", "harmless", "pest-free").
- **Guard-compatible wording.** The on-device output guard drops answers containing these words in any language, so a card that uses them makes every grounded answer silently fall back. Use the alternatives instead:

  | Avoid | Use instead |
  |---|---|
  | kill / killing | stop, keep out, injure (only in "do not harm, catch or injure") |
  | safe / safety / safe distance | stay well back |
  | treatment / treat / first aid | if bitten or stung; get medical care |
  | medicine / medication | see a doctor; go to hospital |
  | poison / poisonous / venom / venomous | strong bite; can make you very ill |
  | spray / chemical / pest control (as a product) | a licensed pest-control professional |
- **Humane and lawful.** No glue boards or open sticky traps where lizards, shrews, birds or pets can reach them. The Animal Welfare Board of India has directed states to ban glue traps (2001 and 2020 circulars). Rodent cards warn against them explicitly. Insect monitoring traps must be covered and placed out of reach.

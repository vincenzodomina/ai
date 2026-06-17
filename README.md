# Vincenzo's Skills & Software development workflow

This is my personal current set of skills and workflow for software development. I use this repository to seed my development environments and share.

The goal is to address every step of the SDLC with processes that work for me and my stack and continuously unblock the agent to work more autonomously, more efficient and more reliable.

## Workflow

1. Bootstrap Cloud dev environment: init.sh script that downloads CLI's, start local db with migrations and seed data, populate .env files and start dev servers.
2. [AGENTS.md](http://agents.md) at root -> Table of contents and overview of the project with pointers to docs + Gates for every step, e.g. Run tests after every change.
3. /dependency-hygiene: so that every new feature starts with updated and audited deps (+ run tests and user testing)
4. /plan-new-feature + First rough and lazy description (often voice dictated brain dump rambling)
5. /grill-me: clarification questions + discuss options + back and forth
6. /write-prd: create PRD specs from grilling conversation content 
7. Get external docs: Read the docs/skills from the external libraries (e.g. ssh supabase.sh)
8. Create other specs & docs: create ARD's, Implementation plans, Documentation with architecture explanations, usage examples and feature descriptions
9. "Create implementation plan from PRD with architecture concepts according to /improve-codebase-architecture"
10. "Please implement according to the specs and /code-guidelines"
11. /gap-analysis: Gives itemized overview of PRD vs implementation. 
12. "Did you implement everything according to spec already? If not, please implement the missing parts according to the specs and /code-guidelines"
13. /handoff: If a separate feature or todo pops up it creates necessary context for a fresh session to continue the work there without polluting the current conversation.
14. Edit & Re-Run prompts: I make heavy use of this via the UI to keep the conversation clean and focused on the current task.
15. /deslop + /improve-code + /improve-codebase-architecture + /improve (from shadcn/improve)
16. /testing-strategy + /write-tests + (Run tests and fix) + (/supabase-testing if database changes)
17. /code-review + Loop over itemized findings with "implement" in new sessions until only minor findings remain.
18. /update-docs: Finds outdated parts in docs and updates them to match the current implementation.
19. /update-changelog: Incredible how much time of my life i spent doing this manually.
20. PR's: Current Claude Code / Codex desktop apps native "Create PR" buttons or via chat is fine.
21. /audit-instructions: At any point you expected different behavior or results, use this skill to audit the inputs and it explains what went wrong and proposes improvements to the skills or prompts.
22. /unblock: If the agent gets stuck or wanders around too long to complete the task this identifies the roadblocks and proposes solutions to its action space to unblock it.


TODO:

- Integrate with /goal: I would like to experiment more with an orchestrator agent that runs this full workflow by prompting a coding agent (like we use cursor) and only interrupts if cursor comes back with valid clarification questions and the orch. agent would then read and decide if really important and only then come back to the user, and that from mobile/desktop synced
- Skill for "Get external docs: Read the docs/skills from the external libraries (e.g. ssh supabase.sh)"
- Skill for "Create other specs & docs: create ARD's, Implementation plans, Documentation with architecture explanations, usage examples and feature descriptions"
- Skill for "Deployment / CI / Provision of domains, cloud resources (Infrastructure as Code?)"
- Test /tdd


## CLI's to be installed

- One CLI for all of Google Workspace — built for humans and AI agents.
https://github.com/googleworkspace/cli

```bash
npm install -g @googleworkspace/cli
```

- Office 2 LLM
https://github.com/vincenzodomina/office2llm

- FFmpeg
https://www.ffmpeg.org/download.html

- ripgrep
https://github.com/BurntSushi/ripgrep
```bash
 brew install ripgrep
```

- Obsidian
CLI comes with local desktop dmg install
```bash
https://github.com/obsidianmd/obsidian-releases/releases/download/v1.12.4/Obsidian-1.12.4.dmg
obsidian help
```

- QMD - Query Markup Documents
https://github.com/tobi/qmd
```bash
npm install -g @tobilu/qmd
qmd collection add ~/vault --name notes
qmd embed
```

## Other Awesome Skills

| Name | Very Short Description | URL |
| --- | --- | --- |
| Supabase Agent Skills | Supabase skills; install with `npx skills add supabase/agent-skills`. | [https://github.com/supabase/agent-skills/tree/main/skills](https://github.com/supabase/agent-skills/tree/main/skills) |
| Agent Browser | Browser automation skills. | [https://github.com/vercel-labs/agent-browser/tree/main/skills](https://github.com/vercel-labs/agent-browser/tree/main/skills) |
| Visual Explainer | HTML pages and decks for reviews, diagrams, and recaps. | [https://github.com/nicobailon/visual-explainer](https://github.com/nicobailon/visual-explainer) |
| Humanizer | Removes AI-writing tells. | [https://github.com/blader/humanizer](https://github.com/blader/humanizer) |
| Caveman | Token-saving prompt style. | [https://github.com/JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) |
| Dependabot | Copilot skill for Dependabot. | [https://skills.sh/github/awesome-copilot/dependabot](https://skills.sh/github/awesome-copilot/dependabot) |
| Grill Me | Matt Pocock's plan stress-test skill. | [https://github.com/mattpocock/skills/blob/main/grill-me/SKILL.md](https://github.com/mattpocock/skills/blob/main/grill-me/SKILL.md) |
| Product Manager Skills | Product management skill framework. | [https://github.com/deanpeters/Product-Manager-Skills](https://github.com/deanpeters/Product-Manager-Skills) |
| Agent Slack | Slack automation CLI for agents. | [https://github.com/stablyai/agent-slack](https://github.com/stablyai/agent-slack) |
| React Doctor | Diagnose and fix React code. | [https://github.com/millionco/react-doctor](https://github.com/millionco/react-doctor) |
| TDD Skill | Test-driven development skill. | [https://github.com/mfranzon/tdd](https://github.com/mfranzon/tdd) |
| Taste Skill | High-agency frontend taste. | [https://github.com/Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) |
| Agent Skills | Addy Osmani's engineering skills. | [https://github.com/addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) |
| Matt Pocock Skills | Personal Claude skills directory. | [https://github.com/mattpocock/skills/tree/main](https://github.com/mattpocock/skills/tree/main) |
| Recursive Mode | Recursive agentic engineering workflow. | [https://github.com/try-works/recursive-mode](https://github.com/try-works/recursive-mode) |
| Rhys Sullivan Skills | Personal skills collection. | [https://github.com/RhysSullivan/skills](https://github.com/RhysSullivan/skills) |
| Superpowers | Agentic skills framework and methodology. | [https://github.com/obra/superpowers](https://github.com/obra/superpowers) |
| Hallmark | Anti-slop design skill. | [https://github.com/nutlope/hallmark](https://github.com/nutlope/hallmark) |
| Spec Kit | Spec-driven development toolkit. | [https://github.com/github/spec-kit](https://github.com/github/spec-kit) |
| Swyx Skills | Agent skills collection. | [https://github.com/swyxio/skills/tree/main#kakuna-codebase-hardening-suite](https://github.com/swyxio/skills/tree/main#kakuna-codebase-hardening-suite) |
| Tufte Claude Skill | Tufte-compliant charting skill. | [https://github.com/aref-vc/tufte-claude-skill](https://github.com/aref-vc/tufte-claude-skill) |
| Autoreview Skill | Automated review skill. | [https://github.com/openclaw/agent-skills/blob/main/skills/autoreview/SKILL.md](https://github.com/openclaw/agent-skills/blob/main/skills/autoreview/SKILL.md) |
| Learn Quiz | Quiz-learning prompt. | [https://gist.github.com/ThariqS/1389dcdff9eba4789887a2211370f06b](https://gist.github.com/ThariqS/1389dcdff9eba4789887a2211370f06b) |
| AI PM OS | Product management AI system. | [https://www.prodmgmt.world/ai-pm-os](https://www.prodmgmt.world/ai-pm-os) |
| GStack | Garry Tan's Claude Code setup. | [https://github.com/garrytan/gstack](https://github.com/garrytan/gstack) |
| Automated Doubt | Development process with automated doubt. | [https://www.alexself.dev/blog/automated-doubt](https://www.alexself.dev/blog/automated-doubt) |
| Agents and Pipelines | Agents, commands, and pipelines. | [https://github.com/aself101/agents-and-pipelines](https://github.com/aself101/agents-and-pipelines) |
| Improve | Audit plans for codebase improvements. | [https://github.com/shadcn/improve](https://github.com/shadcn/improve) |
| Infinite Skills | Infinite Labs Codex skills. | [https://github.com/Infinite-Labs-AI/infinite-skills/tree/main](https://github.com/Infinite-Labs-AI/infinite-skills/tree/main) |
| Superdense | Dense context and skill resource. | [https://github.com/Nimrobo/superdense](https://github.com/Nimrobo/superdense) |

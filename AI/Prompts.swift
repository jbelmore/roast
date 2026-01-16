import Foundation

// MARK: - Report Personality

enum ReportPersonality: String, CaseIterable, Codable {
    case encouraging = "Encouraging"
    case professional = "Professional"
    case neutral = "Neutral"
    case roast = "Roast"

    var icon: String {
        switch self {
        case .encouraging: return "sun.max.fill"
        case .professional: return "briefcase.fill"
        case .neutral: return "equal.circle.fill"
        case .roast: return "flame.fill"
        }
    }

    var description: String {
        switch self {
        case .encouraging:
            return "Supportive coach who celebrates your wins"
        case .professional:
            return "Executive briefing style, data-focused"
        case .neutral:
            return "Balanced and honest observations"
        case .roast:
            return "Savage comedy roast of your habits"
        }
    }

    var color: String {
        switch self {
        case .encouraging: return "green"
        case .professional: return "blue"
        case .neutral: return "gray"
        case .roast: return "orange"
        }
    }

    var isShareable: Bool {
        self == .roast
    }
}

// MARK: - Prompts

enum Prompts {

    // MARK: - System Prompts by Personality

    static func systemPrompt(for personality: ReportPersonality) -> String {
        switch personality {
        case .encouraging:
            return encouragingSystem
        case .professional:
            return professionalSystem
        case .neutral:
            return neutralSystem
        case .roast:
            return roastSystem
        }
    }

    static let encouragingSystem = """
    You are the Roast—a supportive productivity coach who sees the best in people while still being honest. Your job is to analyze a user's weekly computer usage and help them see their progress and potential.

    Your personality:
    - You're like an encouraging friend who genuinely believes in them
    - You find the silver lining without being fake or dismissive
    - You celebrate small wins enthusiastically
    - You frame challenges as opportunities for growth
    - You're warm, supportive, and motivating
    - You use positive language and exclamation points naturally

    What you analyze:
    - Progress and improvements, no matter how small
    - Deep work sessions as major accomplishments
    - Patterns that show dedication and effort
    - Areas of strength to build upon
    - Gentle observations about areas for improvement

    What you DON'T do:
    - Shame or criticize harshly
    - Use negative framing
    - Ignore genuine achievements
    - Be condescending or patronizing
    - Give false praise (be genuinely encouraging, not fake)

    Output format:
    Write an uplifting ~400-600 word weekly report with these sections:
    1. **Your Week in a Nutshell** - One positive, energizing sentence about the week
    2. **Wins Worth Celebrating** - 2-3 achievements or positive patterns with specific numbers
    3. **Hidden Strengths** - Positive patterns they might not have noticed
    4. **Room to Grow** - Gentle, constructive observations framed as opportunities
    5. **Your Challenge for Next Week** - One encouraging, achievable goal

    Use second person ("you"). Be warm and conversational. Use occasional exclamation points where natural!
    """

    static let professionalSystem = """
    You are the Roast—a professional productivity analyst providing executive-level insights. Your job is to deliver a clear, data-driven analysis of weekly computer usage patterns.

    Your personality:
    - You're like a management consultant delivering findings
    - You lead with data and metrics
    - You're objective and analytical
    - You provide clear, actionable recommendations
    - You maintain professional tone throughout
    - You're concise and efficient with words

    What you analyze:
    - Key performance indicators and metrics
    - Productivity efficiency ratios
    - Time allocation across applications
    - Context switching impact on output
    - Week-over-week trend analysis

    What you DON'T do:
    - Use casual language or humor
    - Make emotional appeals
    - Provide vague observations
    - Moralize or lecture
    - Waste words on pleasantries

    Output format:
    Write a professional ~400-600 word weekly report with these sections:
    1. **Executive Summary** - One sentence bottom-line assessment
    2. **Key Metrics** - 2-3 critical data points with analysis
    3. **Trend Analysis** - Patterns and their business implications
    4. **Performance Highlights** - Areas of strong execution
    5. **Recommendation** - One prioritized action item with expected impact

    Use second person ("you"). Maintain professional tone. Use precise language and specific metrics.
    """

    static let neutralSystem = """
    You are the Roast—a balanced and honest productivity analyst. Your job is to analyze a user's weekly computer usage and tell them the truth about their behavior patterns. Not cruel, but direct. Not preachy, but constructive.

    Your personality:
    - You're like a wise friend who doesn't sugarcoat things
    - You notice patterns the user might be in denial about
    - You're specific and actionable, not vague
    - You use concrete numbers to make points land
    - You acknowledge what's working, not just problems
    - You're occasionally witty but never mean

    What you analyze:
    - Compulsive checking behaviors (brief, repeated app visits)
    - Context switching and fragmentation
    - "Productive theater" (apps open but not really working)
    - Time of day patterns
    - Progress or regression from previous weeks
    - The gap between likely intentions and actual behavior

    What you DON'T do:
    - Moralize about screen time in general
    - Assume all social media is bad
    - Ignore context (maybe they NEED to check Slack a lot)
    - Give generic advice like "try the Pomodoro technique"
    - Be relentlessly negative

    Output format:
    Write a candid ~400-600 word weekly report with these sections:
    1. **The Headline** - One sentence capturing the week's main pattern
    2. **What Actually Happened** - 2-3 key behavioral observations with specific numbers
    3. **The Patterns You Might Not See** - Deeper analysis of habits/compulsions
    4. **What's Working** - Genuine positives worth reinforcing
    5. **One Thing to Try** - A single, specific, actionable suggestion for next week

    Use second person ("you"). Be conversational. No bullet points in the main analysis—write in flowing paragraphs within each section.
    """

    static let roastSystem = """
    You are the Roast: ROAST MODE—a savage comedy roaster who absolutely destroys people based on their computer usage. Your job is to write a hilarious, brutal roast of someone's productivity (or lack thereof). Think Comedy Central Roast meets screen time report.

    Your personality:
    - You're a professional roast comedian who specializes in productivity burns
    - You find the most embarrassing, cringe-worthy patterns and DESTROY them
    - You use creative insults, analogies, and pop culture references
    - You're theatrical and dramatic about mundane things
    - You never actually mean harm—it's all in good fun
    - You occasionally break character to acknowledge something genuinely good (before roasting again)

    Your roasting style:
    - Compare their habits to embarrassing things ("You check Slack more often than a teenager checks if their crush texted back")
    - Use exaggeration for comedic effect
    - Create funny hypotheticals ("At this rate, you'll achieve inbox zero approximately never")
    - Mock their app choices and time allocation
    - Invent embarrassing interpretations of their data
    - Use rhetorical questions dripping with sarcasm
    - Include at least 2-3 laugh-out-loud burns

    What you ROAST:
    - Compulsive app checking ("Your relationship with Twitter is more committed than most marriages")
    - Context switching ("You have the attention span of a caffeinated squirrel")
    - Pretending to be productive ("10 hours of 'work' and your most-used app is... YouTube?")
    - Time-wasting patterns with brutal specificity
    - The gap between what they think they're doing vs. reality

    What you DON'T do:
    - Be actually mean-spirited or hurtful
    - Make it personal beyond their computer usage
    - Punch down or be offensive
    - Forget to be FUNNY (this is entertainment!)
    - Hold back—they asked for this

    Output format:
    Write a SAVAGE ~400-600 word roast with these sections:
    1. **The Verdict** - One brutal, quotable headline roast
    2. **The Prosecution Presents** - 2-3 devastating burns based on their actual data
    3. **Exhibit A: Your Browser History (Basically)** - Roast their app usage patterns
    4. **In Your Defense...** - Sarcastically acknowledge ONE good thing before undermining it
    5. **The Sentence** - A funny "punishment" or challenge for next week

    Use second person ("you"). Be theatrical. Make them laugh at themselves. This should be SHAREABLE—something they'd want to post or send to friends because it's so funny.

    END THE ROAST WITH: "🔥 ROASTED BY Roast from Pixel Pantry 🔥" followed by a one-line summary burn they can easily share.
    """

    // MARK: - Daily Summary Prompts

    static func dailySummaryPrompt(for personality: ReportPersonality) -> String {
        switch personality {
        case .encouraging:
            return "You are an encouraging productivity buddy. Give a quick, positive pulse check on today's computer usage in 2-3 sentences. Find something to celebrate!"
        case .professional:
            return "You are a professional analyst. Provide a brief executive summary of today's productivity metrics in 2-3 sentences. Be data-focused and concise."
        case .neutral:
            return "You are a brief, insightful productivity observer. Give a quick pulse check on today's computer usage in 2-3 sentences. Be direct but not harsh. Point out one notable pattern or observation."
        case .roast:
            return "You are a savage roast comedian. Roast this person's day in 2-3 brutal but funny sentences. Make them laugh at themselves. End with a fire emoji."
        }
    }

    // MARK: - User Prompt Builders

    static func buildWeeklyAnalysisPrompt(stats: WeeklyStats, personality: ReportPersonality) -> String {
        var prompt = """
        Here's my computer usage data for the week of \(TimeFormatters.formatDate(stats.weekStart)) to \(TimeFormatters.formatDate(stats.weekEnd)):

        ## Raw Numbers

        Total tracked time: \(TimeFormatters.formatDurationLong(stats.totalTrackedTime))
        Total apps used: \(stats.uniqueApps)
        Total context switches: \(stats.totalContextSwitches)
        Average time before switching: \(TimeFormatters.formatDuration(stats.averageSessionLength))

        ## App Breakdown (top 10 by time)

        """

        for app in stats.appUsage.prefix(10) {
            prompt += """
            - \(app.appName): \(app.formattedTotalTime) total, \(app.totalSessions) sessions, avg \(app.formattedAvgSession) per session, \(app.briefVisits) brief checks (<30s)

            """
        }

        prompt += """

        ## Behavioral Patterns

        Compulsive checking detected:
        """

        if stats.compulsiveChecks.isEmpty {
            prompt += "\nNo significant compulsive checking patterns detected.\n"
        } else {
            for pattern in stats.compulsiveChecks {
                prompt += """

                - \(pattern.appName): Opened \(pattern.formattedChecksPerDay)x/day, averaging \(pattern.formattedAvgDuration) each time
                """
                if !pattern.triggerApps.isEmpty {
                    prompt += " (often after: \(pattern.triggerApps.joined(separator: ", ")))"
                }
            }
            prompt += "\n"
        }

        prompt += """

        Deep work sessions (30+ min uninterrupted):
        """

        if stats.deepWorkSessions.isEmpty {
            prompt += "\nNo deep work sessions detected this week.\n"
        } else {
            for session in stats.deepWorkSessions.prefix(5) {
                prompt += """

                - \(TimeFormatters.formatDate(session.date)): \(session.formattedDuration) in \(session.primaryApp)
                """
            }
            prompt += "\n"
        }

        prompt += """

        Fragmented hours (10+ switches): \(stats.fragmentedHours.count) hours this week were highly fragmented

        """

        // Find most fragmented and most focused days
        if let mostFragmented = stats.dailyBreakdowns.max(by: { $0.fragmentedHours < $1.fragmentedHours }) {
            prompt += "Most fragmented day: \(mostFragmented.dayOfWeek) (\(mostFragmented.fragmentedHours) fragmented hours)\n"
        }

        if let mostFocused = stats.dailyBreakdowns.max(by: { $0.deepWorkMinutes < $1.deepWorkMinutes }) {
            prompt += "Most focused day: \(mostFocused.dayOfWeek) (\(mostFocused.deepWorkMinutes) min of deep work)\n"
        }

        prompt += """

        ## Time of Day Patterns

        Most productive hours: \(stats.peakProductivityHours.map { TimeFormatters.formatHour($0) }.joined(separator: ", "))
        Most distracted hours: \(stats.peakDistractionHours.map { TimeFormatters.formatHour($0) }.joined(separator: ", "))

        """

        if let comparison = stats.weekOverWeekChanges {
            prompt += """

            ## vs. Last Week

            Context switches: \(comparison.contextSwitchChangeFormatted)
            Deep work sessions: \(comparison.deepWorkSessionsChange > 0 ? "+" : "")\(comparison.deepWorkSessionsChange)
            Average session length: \(comparison.sessionLengthChangeFormatted)
            Total tracked time: \(comparison.totalTimeChangeFormatted)
            """
        }

        prompt += """

        ---

        """

        // Add personality-specific closing prompt
        switch personality {
        case .encouraging:
            prompt += "Analyze this data and help me see my wins and growth opportunities. What should I celebrate? What's one encouraging challenge for next week?"
        case .professional:
            prompt += "Provide a professional analysis of this data. What are the key insights? What's the primary recommendation for improving productivity metrics?"
        case .neutral:
            prompt += "Analyze this data and give me your honest assessment. What patterns do you see? What am I probably lying to myself about? What's one specific thing I could change?"
        case .roast:
            prompt += "DESTROY ME. Roast my productivity habits into oblivion. Be savage, be funny, make me want to share this roast with my friends because it's so brutally accurate and hilarious. Don't hold back!"
        }

        return prompt
    }

    static func buildDailySummaryPrompt(stats: TodayStats, personality: ReportPersonality) -> String {
        var prompt = """
        Today so far:
        - Active time: \(TimeFormatters.formatDuration(stats.totalActiveTime))
        - Context switches: \(stats.contextSwitches)
        - Compulsive checks: \(stats.compulsiveChecks)
        - Deep work: \(stats.deepWorkMinutes) minutes

        Top apps:
        """

        for app in stats.topApps.prefix(5) {
            prompt += "\n- \(app.appName): \(TimeFormatters.formatDuration(app.totalTime))"
        }

        switch personality {
        case .encouraging:
            prompt += "\n\nGive me an encouraging pulse check on my day! What's going well?"
        case .professional:
            prompt += "\n\nProvide a brief executive summary of today's productivity."
        case .neutral:
            prompt += "\n\nGive me a brief pulse check on my day so far."
        case .roast:
            prompt += "\n\nRoast my day in 2-3 brutal sentences. Make it funny!"
        }

        return prompt
    }

    // MARK: - Legacy Support (for backwards compatibility)

    static let honestyMirrorSystem = neutralSystem
    static let dailySummarySystem = "You are a brief, insightful productivity observer. Give a quick pulse check on today's computer usage in 2-3 sentences. Be direct but not harsh. Point out one notable pattern or observation."

    static func buildWeeklyAnalysisPrompt(stats: WeeklyStats) -> String {
        buildWeeklyAnalysisPrompt(stats: stats, personality: .neutral)
    }

    static func buildDailySummaryPrompt(stats: TodayStats) -> String {
        buildDailySummaryPrompt(stats: stats, personality: .neutral)
    }
}

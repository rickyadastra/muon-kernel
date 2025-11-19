module datetime;

macro bool @is_leap_year(#year) => (#year % 4 == 0 && #year % 100 != 0) || (#year % 400 == 0);

fn Datetime to_datetime(int year, int month, int day, int hour, int minute, int second) {
    return {
        year, month, day, hour, minute, second
    };
}

fn Datetime epoch_to_datetime(ulong time) {
    Datetime dt = EPOCH_DATE;

    dt.second = (uint)(time % 60);
    time /= 60;
    dt.minute = (uint)(time % 60);
    time /= 60;
    dt.hour = (uint)(time % 24);
    time /= 24;

    ulong days = time;

    while (days >= (@is_leap_year(dt.year) ? LEAP_YEAR_DAYS : NORMAL_YEAR_DAYS)) {
        days -= @is_leap_year(dt.year) ? LEAP_YEAR_DAYS : NORMAL_YEAR_DAYS;
        dt.year++;
    }

    uint[] days_in_month = DAYS_IN_MONTH[..];
    if (@is_leap_year(dt.year)) days_in_month[2] = 29;

    dt.month = 1;
    while (days >= days_in_month[dt.month]) {
        days -= days_in_month[dt.month];
        dt.month++;
    }

    dt.day = (uint)(days + 1);

    return dt;
}

fn ulong? Datetime.seconds_since_epoch(&self) {
    if (self.year < 1970) return INVALID_YEAR?;

    ulong totalDays = 0;

    // full days per year since 1970 to last full year
    for (usz y = 1970; y < self.year; y++) {
        totalDays += @is_leap_year(y) ? LEAP_YEAR_DAYS : NORMAL_YEAR_DAYS;
    }

    // full days per month in current year to last full month
    for (usz m = 1; m < self.month; m++) {
        if (m == 2 && @is_leap_year(self.year)) totalDays += 1;
        totalDays += DAYS_IN_MONTH[m];
    }

    // full days up to last full day (yesterday)
    totalDays += self.day - 1ul;

    ulong totalSeconds = totalDays * SECONDS_IN_DAY;
    totalSeconds += self.hour * SECONDS_IN_HOUR;
    totalSeconds += self.minute * SECONDS_IN_MINUTE;
    totalSeconds += self.second;

    return totalSeconds;
}

fn Weekday Datetime.weekday(&self) {
    // Gauss's weekday algorithm
    uint offset = MONTH_OFFSET[(char)@is_leap_year(self.year)][self.month-1];
    uint weekday = (self.day + offset + 5*((self.year-1)%4) + 4*((self.year-1)%100) + 6*((self.year-1)%400))%7;

    return Weekday.values[weekday];
}

#include "natsort.h"

int compare_right(const QString &leftStr, int left, const QString &rightStr, int right)
{
  int bias = 0;

  for (;; left++, right++) {
    if (left >= leftStr.length() && right < rightStr.length())
      return -1;
    else if (right >= rightStr.length() && left < leftStr.length())
      return +1;
    else if (right >= rightStr.length() && left >= leftStr.length())
      return bias;
    else if (!leftStr[left].isDigit() && !rightStr[right].isDigit())
      return bias;
    else if (!leftStr[left].isDigit())
      return -1;
    else if (!rightStr[right].isDigit())
      return +1;
    else if (leftStr[left] < rightStr[right]) {
      if (!bias)
        bias = -1;
    } else if (leftStr[left] > rightStr[right]) {
      if (!bias)
        bias = +1;
    } else if (leftStr[left].isNull() && rightStr[right].isNull())
      return bias;
  }
}

int compare_left(const QString &leftStr, int left, const QString &rightStr, int right)
{
  for (;; left++, right++) {
    if (left >= leftStr.length() && right < rightStr.length())
      return -1;
    else if (right >= rightStr.length() && left < leftStr.length())
      return +1;
    else if (right >= rightStr.length() && left >= leftStr.length())
      return 0;
    else if (!leftStr[left].isDigit() && !rightStr[right].isDigit())
      return 0;
    else if (!leftStr[left].isDigit())
      return -1;
    else if (!rightStr[right].isDigit())
      return +1;
    else if (leftStr[left] < rightStr[right])
      return -1;
    else if (leftStr[left] > rightStr[right])
      return +1;
  }
}

int natural_order_compare(const QString &leftStr, const QString &rightStr, bool fold_case)
{
  if (leftStr.isEmpty() && rightStr.isEmpty())
    return 0;

  int ai, bi;
  QChar ca, cb;
  int fractional, result;

  ai = bi = 0;
  const int aSize = leftStr.size();
  const int bSize = rightStr.size();

  while (true) {
    ca = leftStr[ai]; cb = rightStr[bi];

    while (ca.isSpace() && ++ai < aSize)
      ca = leftStr[ai];

    while (cb.isSpace() && ++bi < bSize)
      cb = rightStr[bi];

    if (ca.isDigit() && cb.isDigit()) {
      fractional = (ca == QLatin1Char('0') || cb == QLatin1Char('0'));

      if (fractional) {
        if ((result = compare_left(leftStr, ai, rightStr, bi)) != 0)
          return result;
      } else {
        if ((result = compare_right(leftStr, ai, rightStr, bi)) != 0)
          return result;
      }
    }

    if (ca.isNull() && cb.isNull()) {
      return 0;
    }

    if (fold_case) {
      ca = ca.toUpper();
      cb = cb.toUpper();
    }

    if (ca < cb)
      return -1;
    else if (ca > cb)
      return +1;

    ++ai; ++bi;
    if(aSize == ai) {
      return aSize <= bSize ? -1 : 1;
    }
    if (bSize == bi) {
      return bSize <= aSize ? 1 : -1;
    }
  }
}

bool caseSensitiveNaturalOrderLessThen(const QString &left, const QString &right)
{
  return (natural_order_compare(left, right, false) < 0);
}

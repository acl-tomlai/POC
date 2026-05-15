import {
  Spinner,
  Table,
  TableBody,
  TableCell,
  TableHeader,
  TableHeaderCell,
  TableRow,
  Text,
  makeStyles,
  tokens,
} from '@fluentui/react-components';
import type { ReactNode } from 'react';

const useStyles = makeStyles({
  wrapper: {
    backgroundColor: tokens.colorNeutralBackground1,
    border: `1px solid ${tokens.colorNeutralStroke2}`,
    borderRadius: tokens.borderRadiusMedium,
    overflow: 'hidden',
  },
  state: {
    padding: '48px 16px',
    textAlign: 'center',
    color: tokens.colorNeutralForeground3,
  },
  clickableRow: {
    cursor: 'pointer',
    ':hover': {
      backgroundColor: tokens.colorNeutralBackground1Hover,
    },
  },
});

export interface DataTableColumn<T> {
  key: string;
  header: string;
  render: (row: T) => ReactNode;
  width?: string;
}

interface DataTableProps<T> {
  columns: DataTableColumn<T>[];
  rows: T[] | undefined;
  rowKey: (row: T) => string;
  isLoading?: boolean;
  isError?: boolean;
  emptyMessage?: string;
  onRowClick?: (row: T) => void;
}

export function DataTable<T>({
  columns,
  rows,
  rowKey,
  isLoading,
  isError,
  emptyMessage = 'No records yet.',
  onRowClick,
}: DataTableProps<T>) {
  const styles = useStyles();

  if (isLoading) {
    return (
      <div className={styles.wrapper}>
        <div className={styles.state}>
          <Spinner label="Loading…" />
        </div>
      </div>
    );
  }

  if (isError) {
    return (
      <div className={styles.wrapper}>
        <div className={styles.state}>
          <Text>Failed to load. Please refresh and try again.</Text>
        </div>
      </div>
    );
  }

  if (!rows || rows.length === 0) {
    return (
      <div className={styles.wrapper}>
        <div className={styles.state}>
          <Text>{emptyMessage}</Text>
        </div>
      </div>
    );
  }

  return (
    <div className={styles.wrapper}>
      <Table>
        <TableHeader>
          <TableRow>
            {columns.map((c) => (
              <TableHeaderCell key={c.key} style={c.width ? { width: c.width } : undefined}>
                {c.header}
              </TableHeaderCell>
            ))}
          </TableRow>
        </TableHeader>
        <TableBody>
          {rows.map((row) => (
            <TableRow
              key={rowKey(row)}
              className={onRowClick ? styles.clickableRow : undefined}
              onClick={onRowClick ? () => onRowClick(row) : undefined}
            >
              {columns.map((c) => (
                <TableCell key={c.key}>{c.render(row)}</TableCell>
              ))}
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}

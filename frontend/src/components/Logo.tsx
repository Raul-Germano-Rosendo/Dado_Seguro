export default function Logo({ size = 40 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 48 48" aria-hidden="true">
      <rect width="48" height="48" rx="12" fill="var(--blue-500)" />
      <path d="M24 9l12 4.5V23c0 7.5-5.2 12.8-12 16.5C17.2 35.8 12 30.5 12 23v-9.5z" fill="#fff" />
      <rect x="19" y="21" width="10" height="8" rx="2" fill="var(--blue-500)" />
      <path d="M21 21v-2.5a3 3 0 016 0V21" fill="none" stroke="var(--blue-500)" strokeWidth="2" />
    </svg>
  )
}

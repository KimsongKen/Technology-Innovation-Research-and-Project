package Demo;

import javax.swing.*;
import java.awt.*;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.awt.geom.RoundRectangle2D;

public class SmartAdaptiveClinicalAssistant extends JFrame {

    private final Color BG_COLOR = new Color(245, 248, 250);
    private final Color CARD_BG = Color.WHITE;
    private final Color ACCENT_BLUE = new Color(41, 98, 255);
    private final Color TEXT_PRIMARY = new Color(33, 33, 33);
    private final Color TEXT_SECONDARY = new Color(97, 97, 97);

    // ========== 新增：用于页面切换 ==========
    private CardLayout cardLayout;
    private JPanel contentPanel;
    // =====================================

    public SmartAdaptiveClinicalAssistant() {
        initUI();
    }

    private void initUI() {
        setTitle("SACA - Smart Adaptive Clinical Assistant");
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setSize(900, 650);
        setLocationRelativeTo(null);
        setMinimumSize(new Dimension(800, 550));

        // ========== 新增：用 CardLayout 包装主内容 ==========
        cardLayout = new CardLayout();
        contentPanel = new JPanel(cardLayout);
        contentPanel.add(createHomePanel(), "home");
        contentPanel.add(new SpeechPanel(this), "speech");
        contentPanel.add(new SelectionPanel(this), "selection");  // ← 加这行 跳转到selectionPanel
        add(contentPanel);
        // ================================================
    }

    // ========== 新增：把原来的 initUI 内容移到这里 ==========
    private JPanel createHomePanel() {
        JPanel mainPanel = new JPanel(new BorderLayout(20, 20));
        mainPanel.setBackground(BG_COLOR);
        mainPanel.setBorder(BorderFactory.createEmptyBorder(30, 40, 30, 40));

        mainPanel.add(createHeaderPanel(), BorderLayout.NORTH);
        mainPanel.add(createCardPanel(), BorderLayout.CENTER);
        mainPanel.add(createFooterPanel(), BorderLayout.SOUTH);

        return mainPanel;
    }
    // =====================================================

    // ========== 新增：供 SpeechPanel 调用的返回方法 ==========
    public void showHome() {
        cardLayout.show(contentPanel, "home");
    }
    // =====================================================

    private JPanel createHeaderPanel() {
        JPanel header = new JPanel(new BorderLayout());
        header.setOpaque(false);

        JLabel titleLabel = new JLabel("Smart Adaptive Clinical Assistant");
        titleLabel.setFont(new Font("Segoe UI", Font.BOLD, 32));
        titleLabel.setForeground(TEXT_PRIMARY);

        JLabel subtitleLabel = new JLabel("Choose input mode to begin documentation");
        subtitleLabel.setFont(new Font("Segoe UI", Font.PLAIN, 16));
        subtitleLabel.setForeground(TEXT_SECONDARY);

        JPanel titlePanel = new JPanel(new GridBagLayout());
        titlePanel.setOpaque(false);
        GridBagConstraints gbc = new GridBagConstraints();
        gbc.gridwidth = GridBagConstraints.REMAINDER;
        gbc.anchor = GridBagConstraints.WEST;
        titlePanel.add(titleLabel, gbc);
        titlePanel.add(Box.createVerticalStrut(5), gbc);
        titlePanel.add(subtitleLabel, gbc);

        header.add(titlePanel, BorderLayout.WEST);

        JPanel statusPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT, 10, 5));
        statusPanel.setOpaque(false);
        JLabel statusIcon = new JLabel("🟢");
        statusIcon.setFont(new Font("Segoe UI Emoji", Font.PLAIN, 16));
        JLabel statusText = new JLabel("System Online");
        statusText.setFont(new Font("Segoe UI", Font.PLAIN, 14));
        statusText.setForeground(TEXT_SECONDARY);
        statusPanel.add(statusIcon);
        statusPanel.add(statusText);
        header.add(statusPanel, BorderLayout.EAST);

        return header;
    }

    private JPanel createCardPanel() {
        JPanel cardContainer = new JPanel(new GridBagLayout());
        cardContainer.setOpaque(false);

        JPanel cardsWrapper = new JPanel(new GridLayout(1, 3, 30, 0));
        cardsWrapper.setOpaque(false);

        cardsWrapper.add(createCard("✍️", "Text / Write",
                "Type or dictate structured notes. Use templates for speed and consistency.",
                ACCENT_BLUE,
                () -> JOptionPane.showMessageDialog(this, "Opening Text Editor", "Text Input", JOptionPane.INFORMATION_MESSAGE)));

        // ========== 修改：Speech 卡片点击跳转到 speech 页面 ==========
        cardsWrapper.add(createCard("🎤", "Speech",
                "Real-time speech recognition. Transcribe conversations or dictate notes.",
                new Color(0, 150, 136),
                () -> cardLayout.show(contentPanel, "speech")));  // 改这一行
        // =========================================================

        cardsWrapper.add(createCard("🖱️", "Selection",
                "Point-and-click picklists, anatomical maps, and coded terminology.",
                new Color(213, 0, 102),
                () -> cardLayout.show(contentPanel, "selection")));  // 改这一行
//                () -> JOptionPane.showMessageDialog(this, "Loading Selection View", "Selection Input", JOptionPane.INFORMATION_MESSAGE)));

        cardContainer.add(cardsWrapper);
        return cardContainer;
    }

    private JPanel createCard(String emoji, String title, String description, Color accentColor, Runnable onClick) {
        JPanel card = new JPanel() {
            @Override
            protected void paintComponent(Graphics g) {
                Graphics2D g2 = (Graphics2D) g.create();
                g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
                g2.setColor(new Color(0, 0, 0, 15));
                g2.fill(new RoundRectangle2D.Double(2, 2, getWidth() - 4, getHeight() - 4, 20, 20));
                g2.setColor(CARD_BG);
                g2.fill(new RoundRectangle2D.Double(0, 0, getWidth() - 4, getHeight() - 4, 20, 20));
                g2.dispose();
                super.paintComponent(g);
            }
        };

        card.setOpaque(false);
        card.setLayout(new BoxLayout(card, BoxLayout.Y_AXIS));
        card.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(230, 230, 230), 1),
                BorderFactory.createEmptyBorder(25, 25, 25, 25)));
        card.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));

        JLabel emojiLabel = new JLabel(emoji);
        emojiLabel.setFont(new Font("Segoe UI Emoji", Font.PLAIN, 48));
        emojiLabel.setAlignmentX(Component.LEFT_ALIGNMENT);

        JLabel titleLabel = new JLabel(title);
        titleLabel.setFont(new Font("Segoe UI", Font.BOLD, 24));
        titleLabel.setForeground(TEXT_PRIMARY);
        titleLabel.setAlignmentX(Component.LEFT_ALIGNMENT);
        titleLabel.setBorder(BorderFactory.createEmptyBorder(15, 0, 10, 0));

        JLabel descLabel = new JLabel("<html><body style='width: 180px'>" + description + "</body></html>");
        descLabel.setFont(new Font("Segoe UI", Font.PLAIN, 14));
        descLabel.setForeground(TEXT_SECONDARY);
        descLabel.setAlignmentX(Component.LEFT_ALIGNMENT);

        JSeparator sep = new JSeparator(SwingConstants.HORIZONTAL);
        sep.setMaximumSize(new Dimension(Integer.MAX_VALUE, 1));
        sep.setForeground(accentColor);
        sep.setBackground(accentColor);
        sep.setAlignmentX(Component.LEFT_ALIGNMENT);

        JPanel spacer = new JPanel();
        spacer.setOpaque(false);
        spacer.setMaximumSize(new Dimension(Integer.MAX_VALUE, 20));
        spacer.setAlignmentX(Component.LEFT_ALIGNMENT);

        card.add(emojiLabel);
        card.add(titleLabel);
        card.add(descLabel);
        card.add(Box.createVerticalGlue());
        card.add(spacer);
        card.add(sep);

        card.addMouseListener(new MouseAdapter() {
            @Override
            public void mouseEntered(MouseEvent e) {
                card.setBorder(BorderFactory.createCompoundBorder(
                        BorderFactory.createLineBorder(accentColor, 2),
                        BorderFactory.createEmptyBorder(24, 24, 24, 24)));
            }

            @Override
            public void mouseExited(MouseEvent e) {
                card.setBorder(BorderFactory.createCompoundBorder(
                        BorderFactory.createLineBorder(new Color(230, 230, 230), 1),
                        BorderFactory.createEmptyBorder(25, 25, 25, 25)));
            }

            @Override
            public void mouseClicked(MouseEvent e) {
                onClick.run();
            }
        });

        return card;
    }

    private JPanel createFooterPanel() {
        JPanel footer = new JPanel(new BorderLayout());
        footer.setOpaque(false);
        JLabel hint = new JLabel("SACA v1.0  |  Smart Adaptive Clinical Assistant  |  For demonstration purposes");
        hint.setFont(new Font("Segoe UI", Font.PLAIN, 12));
        hint.setForeground(new Color(150, 150, 150));
        footer.add(hint, BorderLayout.WEST);
        return footer;
    }

    public static void main(String[] args) {
        try {
            UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
        } catch (Exception e) {
            e.printStackTrace();
        }

        SwingUtilities.invokeLater(() -> {
            new SmartAdaptiveClinicalAssistant().setVisible(true);
        });
    }
}
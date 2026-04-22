package Demo;


import javax.swing.*;
import java.awt.*;

public class SpeechPanel4 extends JPanel {

    private SmartAdaptiveClinicalAssistant mainFrame;
    private JTextArea textArea;

    public SpeechPanel4(SmartAdaptiveClinicalAssistant frame) {
        this.mainFrame = frame;
        setBackground(Color.WHITE);
        setLayout(new BorderLayout(10, 10));
        setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20));

        // 顶部
        JPanel topPanel = new JPanel(new BorderLayout());
        topPanel.setBackground(Color.WHITE);

        JLabel title = new JLabel("Speech", SwingConstants.CENTER);
        title.setFont(new Font("Arial", Font.BOLD, 24));
        topPanel.add(title, BorderLayout.CENTER);

        add(topPanel, BorderLayout.NORTH);

        // 中间
        JPanel centerPanel = new JPanel(new BorderLayout(10, 10));
        centerPanel.setBackground(Color.WHITE);

        JLabel question = new JLabel("Define the severity", SwingConstants.CENTER);
        question.setFont(new Font("Arial", Font.BOLD, 18));
        centerPanel.add(question, BorderLayout.NORTH);

        textArea = new JTextArea();
        textArea.setFont(new Font("Arial", Font.PLAIN, 14));
        textArea.setLineWrap(true);
        textArea.setWrapStyleWord(true);
        textArea.setBorder(BorderFactory.createLineBorder(Color.LIGHT_GRAY));

        JScrollPane scroll = new JScrollPane(textArea);
        scroll.setPreferredSize(new Dimension(400, 150));
        centerPanel.add(scroll, BorderLayout.CENTER);

        add(centerPanel, BorderLayout.CENTER);

        // 底部
        JPanel bottomPanel = new JPanel(new FlowLayout(FlowLayout.CENTER, 20, 10));
        bottomPanel.setBackground(Color.WHITE);

        JButton backBtn = new JButton("← Back");
        backBtn.setFont(new Font("Arial", Font.PLAIN, 14));
        backBtn.addActionListener(e -> mainFrame.showHome());

        JButton nextBtn = new JButton("Next →");
        nextBtn.setFont(new Font("Arial", Font.PLAIN, 14));
        nextBtn.addActionListener(e -> {
            // 关键：这里改成 SpeechPanel3
            mainFrame.getContentPane().removeAll();
            mainFrame.getContentPane().add(new SpeechPanel5(mainFrame));
            mainFrame.revalidate();
            mainFrame.repaint();
        });

        bottomPanel.add(backBtn);
        bottomPanel.add(nextBtn);
        add(bottomPanel, BorderLayout.SOUTH);
    }
}
